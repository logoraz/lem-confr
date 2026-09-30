(defpackage #:lem-confr/core/filer
  (:use #:cl #:lem)
  (:import-from #:lem/filer
                #:render
                #:root-item
                #:filer-buffer
                #:item-pathname
                #:directory-item
                #:directory-item-open-p
                #:directory-item-children
                #:create-directory-children)
  (:export #:filer-refresh
           #:filer-create-directory)
  (:documentation "Filer Extensions -> dired style"))

(in-package #:lem-confr/core/filer)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Filer Extensions

(defun refresh-directory-item (item)
  "Recursively re-scan ITEM's children from disk, for ITEM and every
currently-open directory beneath it, so new/removed entries appear."
  (when (and (typep item 'directory-item) (directory-item-open-p item))
    (let ((was-open (mapcar #'item-pathname
                            (remove-if-not
                             (lambda (c) (and (typep c 'directory-item)
                                              (directory-item-open-p c)))
                             (directory-item-children item)))))
      (setf (directory-item-children item) (create-directory-children (item-pathname item)))
      (dolist (child (directory-item-children item))
        (when (and (typep child 'directory-item)
                   (member (item-pathname child) was-open :test #'uiop:pathname-equal))
          (setf (directory-item-open-p child) t)
          (refresh-directory-item child))))))

(defun filer-refresh ()
  "Re-render the current *Filer* buffer."
  (let ((buf (filer-buffer)))
    (if buf
        (let ((root (root-item buf)))
          (refresh-directory-item root)
          (render buf root))
        (editor-error "Filer is not active"))))

(defun filer-create-directory (name)
  "Create directory NAME inside the directory at point in the current
*Filer* buffer — the item itself if it's a directory, its parent if
it's a file, or the tree root if point isn't on anything — then
refresh the view."
  (let ((buf (filer-buffer)))
    (unless buf
      (editor-error "Filer is not active"))
    (let* ((item (text-property-at (back-to-indentation (current-point)) :item))
           (target (cond ((null item) (item-pathname (root-item buf)))
                         ((typep item 'directory-item) (item-pathname item))
                         (t (uiop:pathname-directory-pathname (item-pathname item)))))
           (path (merge-pathnames (uiop:ensure-directory-pathname name) target)))
      (ensure-directories-exist path)
      (filer-refresh)
      path)))

#+(or)
(defun filer-create-directory (name)
  "Create directory NAME inside the directory the current *Filer* buffer
is showing, then refresh the view."
  (let ((buf (filer-buffer)))
    (unless buf
      (editor-error "Filer is not active"))
    (let ((path (merge-pathnames (uiop:ensure-directory-pathname name)
                                 (item-pathname (root-item buf)))))
      (ensure-directories-exist path)
      (filer-refresh)
      path)))
