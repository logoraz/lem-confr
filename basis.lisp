;;;; basis.lisp - Deploy basis  Lisp Environment for lem-confr
(require :sb-posix)

(defpackage #:clbasis
  (:use #:cl)
  (:export #:bootstrap
           #:install-ocicl-deps)
  (:documentation "Script to bootstrap :aoforce"))

(in-package #:clbasis)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Create Symlinks (SBCL only)

(defun create-symlink (source target &key force)
  "Create a symlink from SOURCE to TARGET.
If FORCE is true, remove existing file/symlink at TARGET first.
Returns T if symlink was created, NIL if it already existed and FORCE was nil."
  (let ((source-path (uiop:native-namestring (uiop:ensure-pathname source)))
        (target-path (uiop:native-namestring (uiop:ensure-pathname target))))
    (when (probe-file target-path)
      (if force
          (progn
            (format t "Removing existing file at: ~A~%" target-path)
            (delete-file target-path))
          (progn
            (format t "Skipping (already exists): ~A~%" target-path)
            (return-from create-symlink nil))))
    (format t "Creating symlink: ~A -> ~A~%" target-path source-path)
    (sb-posix:symlink source-path target-path)
    t))

;; TODO: Refactor to take in a list of deps as opposed to just a string?
(defun install-ocicl-deps (deps dir)
  "Install ocicl dependencies (DEPS) for nxconfig."
  (uiop:run-program (concatenate 'string "ocicl install "
                                 deps)
                    :directory dir
                    :output :string))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Common Lisp Environment Bootstrap

(defun bootstrap (&key (implementations '(:sbcl :clasp)) force)
  "Bootstrap ocicl env by deploying rc symlinks for the specified implementations."
  
  (format t "~%Bootstrapping clbasis configuration...~%~%")
  
  (let ((clfiles-dir (merge-pathnames #P"files/common-lisp/"
                                      (uiop:getcwd))))
    
    (format t "Using directory: ~A~%~%" clfiles-dir)
    
    (ensure-directories-exist (merge-pathnames #P"lem/ocicl/"
                                               (uiop:xdg-config-home)))
    
    (dolist (entry '((:sbcl  "dot-sbclrc.lisp"  "~/.sbclrc")
                     (:clasp "dot-clasprc.lisp" "~/.clasprc")
                     (:ecl   "dot-eclrc.lisp"   "~/.eclrc")))
      (destructuring-bind (impl src dest) entry
        (when (member impl implementations)
          (create-symlink (merge-pathnames src clfiles-dir)
                          (pathname dest)
                          :force force))))
    
    (format t "~%Setup complete!~%")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Run Bootstrap
;;; sbcl --load bootstrap.lisp

(bootstrap :implementations '(:sbcl :clasp :ecl) :force t)
(sb-ext:quit)