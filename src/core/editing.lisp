(defpackage #:lem-confr/editing
  (:use #:cl #:lem)
  (:import-from #:lem-core/commands/file
                #:delete-trailing-whitespace-on-writing-file)
  (:export #:fill-column
           #:split-words
           #:wrap-words
           #:paragraph-bounds)
  (:documentation "General text-editing behavior."))

(in-package #:lem-confr/editing)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Trailing Whitespace

;; See lem-core/commands/edit.lisp, lem-core/commands/file.lisp
(setf (variable-value 'delete-trailing-whitespace-on-writing-file :global) t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Fill Paragraph
;;;
;;; Lem has no fill-paragraph analogous to Emacs's M-q — built here on top
;;; of the existing forward-paragraph/backward-paragraph motion primitives
;;; in lem-core/commands/word.lisp.

(define-editor-variable fill-column 80
  "Target line width for fill-paragraph.")

(defun split-words (string)
  "Split STRING into a list of whitespace-delimited words, collapsing
consecutive whitespace and discarding empty pieces."
  (loop :with words = '()
        :with start = nil
        :for i :below (length string)
        :for char = (char string i)
        :for whitespace-p = (member char '(#\space #\tab #\newline #\return))
        :do (cond
              ((and (not whitespace-p) (not start))
               (setf start i))
              ((and whitespace-p start)
               (push (subseq string start i) words)
               (setf start nil)))
        :finally (when start (push (subseq string start (length string)) words))
                 (return (nreverse words))))

(defun wrap-words (words fill-column)
  "Greedily wrap WORDS into lines no wider than FILL-COLUMN, returning
one string with newlines between lines."
  (with-output-to-string (out)
    (let ((col 0) (first-on-line t))
      (dolist (word words)
        (let ((word-len (length word)))
          (cond
            (first-on-line
             (write-string word out)
             (setf col word-len first-on-line nil))
            ((<= (+ col 1 word-len) fill-column)
             (write-char #\space out)
             (write-string word out)
             (incf col (1+ word-len)))
            (t
             (write-char #\newline out)
             (write-string word out)
             (setf col word-len))))))))

(defun paragraph-bounds ()
  "Return (values start-point end-point) for the paragraph containing
the current point, leaving the actual cursor position undisturbed."
  (let ((origin (copy-point (current-point) :temporary)))
    (backward-paragraph)
    (character-offset (current-point) 1)
    (let ((start (copy-point (current-point) :temporary)))
      (move-point (current-point) origin)
      (forward-paragraph)
      (character-offset (current-point) -1)
      (let ((end (copy-point (current-point) :temporary)))
        (move-point (current-point) origin)
        (values start end)))))
