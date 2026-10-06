(defpackage #:lem-confr/base/editing
  (:use #:cl #:lem)
  (:import-from #:lem-core/commands/file
                #:delete-trailing-whitespace-on-writing-file)
  (:export #:fill-column
           #:split-words
           #:wrap-words
           #:paragraph-bounds
           #:fill-text
           #:fill-active-region)
  (:documentation "General text-editing behavior."))

(in-package #:lem-confr/base/editing)


;;; Trailing Whitespace

;; See lem-core/commands/edit.lisp, lem-core/commands/file.lisp
(setf (variable-value 'delete-trailing-whitespace-on-writing-file :global) t)


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
      ;; FORWARD-PARAGRAPH stops on the blank line after the paragraph, or
      ;; at the end of the buffer when no blank line follows.  Back up one
      ;; character only in the first case; in the second we are already at
      ;; the end of the paragraph's last line.
      (when (blank-line-p (current-point))
        (character-offset (current-point) -1))
      (let ((end (copy-point (current-point) :temporary)))
        (move-point (current-point) origin)
        (values start end)))))


;;; At region implementation

(defun blank-string-p (string)
  "True if STRING holds only spaces and tabs, matching Lem's BLANK-LINE-P."
  (every (lambda (char) (member char '(#\space #\tab))) string))

(defun split-lines (string)
  "Split STRING at newlines into a list of lines.
Keeps a trailing empty line when STRING ends in a newline, so that
JOIN-LINES restores the original text exactly."
  (loop :with start = 0
        :for end = (position #\newline string :start start)
        :collect (subseq string start end)
        :while end
        :do (setf start (1+ end))))

(defun join-lines (lines)
  "Join LINES with newlines; the inverse of SPLIT-LINES."
  (format nil "~{~A~^~%~}" lines))

(defun fill-text (text fill-column)
  "Reflow every paragraph in TEXT to fit FILL-COLUMN, returning a new string.
Paragraphs are runs of non-blank lines.  The blank lines between them are
kept exactly as they are, so paragraphs are never merged."
  (let ((output '())
        (paragraph '()))
    (flet ((flush ()
             (when paragraph
               (let ((words (split-words (join-lines (nreverse paragraph)))))
                 (push (wrap-words words fill-column) output))
               (setf paragraph '()))))
      (dolist (line (split-lines text))
        (cond ((blank-string-p line)
               (flush)
               (push line output))
              (t (push line paragraph))))
      (flush))
    (join-lines (nreverse output))))

(defun fill-active-region (buffer fill-column)
  "Reflow each paragraph in the active region of BUFFER to FILL-COLUMN.
The region is widened to whole lines, and a region ending at column 0 stops
at the end of the previous line.  The mark is cancelled afterwards."
  (let ((start (copy-point (region-beginning buffer) :temporary))
        (end (copy-point (region-end buffer) :temporary)))
    (line-start start)
    (when (and (zerop (point-charpos end)) (point< start end))
      (character-offset end -1))
    (line-end end)
    (let* ((old (points-to-string start end))
           (new (fill-text old fill-column)))
      (unless (string= old new)
        (delete-between-points start end)
        (insert-string start new)))
    (buffer-mark-cancel buffer)))
