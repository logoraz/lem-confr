(defpackage #:lem-confr/editing
  (:use #:cl #:lem)
  (:import-from #:lem-core/commands/file
                #:delete-trailing-whitespace-on-writing-file)
  (:documentation "General text-editing behavior."))

(in-package #:lem-confr/editing)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Trailing Whitespace

;; See lem-core/commands/edit.lisp, lem-core/commands/file.lisp
(setf (variable-value 'delete-trailing-whitespace-on-writing-file :global) t)
