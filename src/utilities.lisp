(defpackage #:lem-confr/utilities
  (:use #:cl #:lem)
  (:import-from #:lem-core
                #:lem-home)
  (:export #:executable-find
           #:create-symlink
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


(defun create-symlink (source target &key force)
  "Create a symlink from SOURCE to TARGET.
If FORCE is true, remove existing file/symlink at TARGET first.
Returns T if symlink was created, NIL if it already existed and FORCE was nil."
  (let ((source-path (uiop:native-namestring (uiop:ensure-pathname source)))
        (target-path (uiop:native-namestring (uiop:ensure-pathname target))))
    (when (probe-file target-path)
      (if force
          (progn
            (format t "Removing existing file at: ~A~%~%" target-path)
            (delete-file target-path))
          (progn
            (format t "Skipping (already exists): ~A~%~%" target-path)
            (return-from create-symlink nil))))
    (format t "Creating symlink: ~A -> ~A~%" target-path source-path)
    (sb-posix:symlink source-path target-path)
    t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Other
