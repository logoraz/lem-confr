(defpackage #:lem-confr/lib/syntax
  (:use #:cl #:lem)
  (:export #:load-contrib)
  (:documentation "Macros/Syntax Extensions for lem-confr"))

(in-package #:lem-confr/lib/syntax)


;;; Package Management

(defun load-contrib (system &optional (package system))
  "Load the contrib SYSTEM via ASDF, unless PACKAGE (a package designator,
defaulting to SYSTEM itself) already names a loaded package."
  (unless (find-package package)
    (asdf:load-system system)))


;;; TODO

#+nil
(tagbody
 start
  (format t "looping~%")
  (when (not (done-p)) (go start))
 end
  (format t "done~%"))
