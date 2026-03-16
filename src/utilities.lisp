(defpackage #:lem-confr/utilities
  (:use #:cl #:lem)
  (:import-from #:lem-core
                #:lem-home)
  (:export #:executable-find
           #:cleanup-debug-logs)
  (:documentation "Basic utilities for lem-confr"))

(in-package #:lem-confr/utilities)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; General Utilities
(defun executable-find (program)
  "Find executable PROGRAM in PATH, return full path or NIL if not found (SBCL only)"
  (let* ((path-env (uiop:getenv "PATH"))
         (separator #+windows ";" #-windows ":")
         (paths (when path-env
                  (uiop:split-string path-env :separator separator))))
    (dolist (dir paths)
      (let* ((dir-path (uiop:ensure-directory-pathname dir))
             (candidate (merge-pathnames program dir-path)))
        (when (and (probe-file candidate)
                   (handler-case
                       (let ((stat (sb-posix:stat (namestring candidate))))
                         (plusp (logand (sb-posix:stat-mode stat) #o111)))
                     (error () nil)))
          (return-from executable-find (namestring candidate)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Other
