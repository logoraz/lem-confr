(defpackage #:lem-confr/base/lisp-ide
  (:use #:cl #:lem)
  (:import-from #:lem/line-numbers
                #:line-numbers-mode)
  (:import-from #:lem-lisp-mode
                #:lisp-mode)
  (:import-from #:lem-scheme-mode
                #:scheme-mode)
  (:import-from #:lem-paredit-mode
                #:paredit-mode
                #:paredit-meta-doublequote)
  (:import-from #:lem-confr/lib/utilities
                #:executable-find)
  (:import-from #:lem-confr/lib/syntax
                #:load-contrib)
  (:export #:paredit-quotewrap)
  (:documentation "Lisp IDE Configuration"))

(in-package #:lem-confr/base/lisp-ide)


;;; General Editing
;; Globally Enable Line Numbers:
(line-numbers-mode)


;;; Paredit

;; Enable paredit-mode in lisp-mode
(add-hook *find-file-hook*
          (lambda (buffer)
            (when (eq (buffer-major-mode buffer) 'lisp-mode)
              (change-buffer-mode buffer 'paredit-mode t))))

;; Enable paredit-mode in scheme-mode
(add-hook *find-file-hook*
          (lambda (buffer)
            (when (eq (buffer-major-mode buffer) 'scheme-mode)
              (change-buffer-mode buffer 'paredit-mode t))))

(defun paredit-quotewrap ()
  "Wrap the following s-expression/atom in double quotes, without the leading
space paredit-meta-doublequote leaves behind."
  (paredit-meta-doublequote)
  (delete-next-char))


;;; Lisp Interaction (aka SLIME)
;;;
;;; 1. Change *tmp* buffer to lisp-mode
;;;
;;; 2. Extend implementation detection past sbcl — upstream only checks sbcl
;;;    directly on PATH; Roswell-managed implementations are found separately,
;;;    but Guix-installed ones like clasp are neither.

(change-buffer-mode (get-buffer "*tmp*") 'lisp-mode)

(sb-ext:without-package-locks
  (defun lem-lisp-mode/implementation::list-installed-implementations ()
    "Override upstream's sbcl-only check to also detect clasp, a
Guix-installed implementation that upstream's roswell-based detection
never sees."
    (append (when (executable-find "sbcl") (list "sbcl"))
            (when (executable-find "clasp") (list "clasp")))))

;; Root cause of the clasp branch below: Guix's asdf-build-system/sbcl
;; auto-registers one $XDG_CONFIG_DIRS/common-lisp/source-registry.conf.d/
;; entry per SBCL library in a package's dependency closure — lem pulls in
;; sbcl-micros this way (needed for its own SBCL-side Lisp mode), same as
;; every other sbcl-* library it depends on. That collides with cl-micros,
;; installed separately for clasp: both register an ASDF system literally
;; named "micros", and clasp's own name-based resolution finds sbcl-micros's
;; (SBCL-only) fasls first, well before its :directory entry for cl-micros
;; ever gets consulted. Not a clasp-cl packaging bug — this is structural to
;; how asdf-build-system/sbcl populates that directory for every SBCL
;; library, and would hit any two packages sharing a system name this way.
(sb-ext:without-package-locks
  (defun lem-lisp-mode/internal::send-micros-create-server (process port)
    "Override to drop the hard-coded (asdf:load-asd <path>) step (always
SBCL-resolved from the host), and additionally patch ASDF's resolved
source-registry entry for \"micros\" when the target is clasp — see the
comment above for why clasp's own resolution lands on sbcl-micros's
unreadable fasls otherwise. #+clasp scopes this fix to Clasp alone, since
sbcl should keep using its own fast, precompiled sbcl-micros."
    (lem-process:process-send-input
     process
     "#+clasp
      (setf (gethash \"micros\" asdf/source-registry:*source-registry*)
            (merge-pathnames \"systems/micros.asd\"
                              (merge-pathnames \".guix-home/profile/share/common-lisp/\"
                                                (user-homedir-pathname))))")
    (lem-process:process-send-input
     process
     "(handler-case (eval (read-from-string \"(ql:quickload :micros)\"))
        (error (c) (asdf:load-system :micros)))")
    (lem-process:process-send-input
     process
     (format nil "(micros:create-server :port ~D :dont-close t)~%" port))))


;;; Markdown Mode Enhancement

(add-hook lem-markdown-mode:*markdown-mode-hook*
          (lambda () (load-contrib :confr-md-table)))

;;; CSV Mode with CSV Rainbow Mode

(defun load-csv-mode-for-csv-files (buffer)
  "Load the csv-mode contrib when BUFFER visits a .csv file.
Runs before PROCESS-FILE (weight 5000), so the file type the contrib
registers is in place when Lem picks the buffer's mode."
  (let ((filename (buffer-filename buffer)))
    (when (and filename (equalp (pathname-type filename) "csv"))
      (handler-case (load-contrib :csv-mode)
        (error (condition)
          (message "csv-mode failed to load: ~A" condition))))))

(add-hook *find-file-hook* 'load-csv-mode-for-csv-files 6000)

(defun enable-csv-rainbow-mode (buffer)
  "Turn on csv-rainbow-mode in BUFFER when it is in csv-mode.
Runs after Lem has chosen the buffer's mode (default hook weight).  The
symbols are looked up at run time, because the csv-mode package does not
exist until the contrib has been loaded."
  (let ((csv-package (find-package "CSV-MODE")))
    (when csv-package
      (let ((csv-mode (find-symbol "CSV-MODE" csv-package))
            (rainbow (find-symbol "CSV-RAINBOW-MODE" csv-package)))
        (when (eq (buffer-major-mode buffer) csv-mode)
          (change-buffer-mode buffer rainbow t))))))

(add-hook *find-file-hook* 'enable-csv-rainbow-mode)

;;; TODO
