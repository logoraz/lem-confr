(defpackage #:lem-confr/bug-fixes
  (:use #:cl #:lem)
  (:documentation "Filer Fixes"))

(in-package #:lem-confr/bug-fixes)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Filer

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
