(defpackage #:lem-confr/core/bug-fixes
  (:use #:cl #:lem)
  (:documentation "Bug Fixes where possible..."))

(in-package #:lem-confr/core/bug-fixes)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Filer (Highlighting/Overlay Issue)

(sb-ext:without-package-locks
  (defun lem/filer:render (buffer item)
    "Override to clear the current-file overlay before erasing the buffer.
Upstream's erase-buffer stretches any existing overlay across the entire
freshly-rendered tree instead of collapsing it, visible as the whole
Filer pane highlighting on any directory expand/collapse."
    (lem/filer::clear-current-file-highlight buffer)
    (with-buffer-read-only buffer nil
      (lem/filer::with-fix-scroll ()
        (let ((line (line-number-at-point (buffer-point buffer))))
          (setf (lem/filer:root-item buffer) item)
          (erase-buffer buffer)
          (lem/filer::render-item (buffer-point buffer) item 0)
          (move-to-line (buffer-point buffer) line)
          (back-to-indentation (buffer-point buffer)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Trailing Spaces (Toggle Issue)
;;;
;;; 1. Stale Highlighting on Disable
;;; 2. Stale Highlighting on Re-enable
;;;

;; disable only unhooks scan-trailing-spaces from after-syntax-scan-hook —
;; it never clears highlighting already applied to text scanned before the
;; toggle. clear-space-attribute only runs inside scan-trailing-spaces
;; itself, so disabling the mode leaves already-highlighted trailing
;; spaces stuck with their cyan background until the buffer is reopened.

(sb-ext:without-package-locks
  (defun lem-trailing-spaces::disable ()
    "Override to also clear existing highlighting in every live buffer,
not just unhook future scans — see the comment above for why upstream's
version leaves stale highlighting behind."
    (remove-hook (variable-value 'after-syntax-scan-hook :global)
                 'lem-trailing-spaces::scan-trailing-spaces)
    (dolist (buffer (buffer-list))
      (lem-trailing-spaces::clear-space-attribute (buffer-start-point buffer)
                                                  (buffer-end-point buffer)))))

;; enable only hooks scan-trailing-spaces for future syntax scans — it
;; never applies it to content already in the buffer, so a trailing space
;; unchanged since the mode was last disabled never gets re-highlighted
;; until its line is edited again.

(sb-ext:without-package-locks
  (defun lem-trailing-spaces::enable ()
    "Override to also scan the current buffer immediately on enable, not
just hook future scans — see the comment above. Scoped to the current
buffer only: scan-trailing-spaces checks (current-buffer) internally
regardless of which buffer's points it's given, so looping over every
open buffer here (unlike disable's fix) would check the wrong buffer's
switchability for anything that isn't currently active."
    (add-hook (variable-value 'after-syntax-scan-hook :global)
              'lem-trailing-spaces::scan-trailing-spaces)
    (let ((buffer (current-buffer)))
      (lem-trailing-spaces::scan-trailing-spaces (buffer-start-point buffer)
                                                 (buffer-end-point buffer)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Line Numbers (Read-Only/Temporary Buffer Restriction)
;;;
;;; 1. File Requirement
;;; 2. Over-Broad Fix (Read-Only Alone Wasn't Enough)
;;;
;;; compute-left-display-area-content only draws line numbers when
;;; (buffer-filename (point-buffer point)) is non-nil — a deliberate
;;; upstream restriction, not a bug, that skips rendering entirely for any
;;; buffer with no backing file, *tmp* included.
;;;
;;; Dropping that check outright also lit up numbers in *dashboard* and
;;; *Filer* (read-only) and isearch's/M-x's/find-file's popup buffers
;;; (editable, but built on lem/prompt-window's :temporary t buffers) —
;;; none of which have a file either, but none of which want numbers.
;;; Excluded via buffer-read-only-p and buffer-temporary-p instead of the
;;; file check.

(sb-ext:without-package-locks
  (defmethod lem-core:compute-left-display-area-content
      ((mode lem/line-numbers::line-numbers-mode) buffer point)
    "Override to drop upstream's (buffer-filename ...) guard and exclude
read-only/temporary buffers instead. See lem/line-numbers.lisp's original
method for comparison."
    (unless (or ( buffer-read-only-p buffer) (buffer-temporary-p buffer))
      (multiple-value-bind (computed-line active-line-p)
          (lem/line-numbers::compute-line buffer point)
        (let* ((num-format (or (variable-value
                                'lem/line-numbers::line-number-format
                                :default buffer)
                               (lem/line-numbers::get-buffer-num-format buffer)))
               (string (format nil num-format computed-line))
               (attribute
                 (if active-line-p
                     `((0 ,(length string)
                          lem/line-numbers::active-line-number-attribute))
                     `((0 ,(length string)
                          lem/line-numbers::line-numbers-attribute)))))
          (lem/buffer/line:make-content :string string
                                        :attributes attribute))))))
