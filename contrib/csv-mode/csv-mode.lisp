(uiop:define-package :csv-mode
  (:use :cl :lem)
  (:import-from :lem/language-mode
                #:language-mode)
  (:import-from :lem/language-mode-tools
                #:make-tm-string-region)
  (:import-from :lem/buffer/line
                #:line-previous
                #:line-syntax-context)
  (:export :*csv-mode-hook*
           :csv-mode
           :csv-rainbow-mode)
  (:documentation "CSV file syntax highlighting with rainbow minor mode."))
(in-package :csv-mode)


;;; Code

(defun make-tm-url ()
  "Return a match rule that highlights URLs.
Matches http, https and ftp URLs.  A URL ends at whitespace, a comma or a
double quote, and trailing punctuation such as a period or a closing
parenthesis is left out of the match."
  (make-tm-match "(?:https?|ftp)://[^\\s,\"]*[^\\s,\".;:!?)]"
                 :name 'syntax-function-name-attribute))

(defun make-tmlanguage-csv ()
  "Return the tmlanguage for CSV: comments, quoted values, separators, URLs.
A comment is a line that starts with a hash.  A quoted value is a region
from one double quote to the next, so it spans lines.  A doubled quote
inside it closes and reopens the region, which looks identical.  Everything
inside a quoted value, URLs and commas included, keeps the string color, as
in Emacs csv-mode.  Outside quotes, commas are separators and URLs are
highlighted.

The scanner resumes after each match, and cl-ppcre then treats the resume
point as the start of the line, so a plain \"^#\" would also match a field
that starts with a hash, such as \"#ff0000\".  The \",#\" rule takes that
comma and hash together first, because it is the longer match, and colors
only the comma."
  (make-tmlanguage
   :patterns (make-tm-patterns
              (make-tm-match "^#.*" :name 'syntax-comment-attribute)
              (make-tm-string-region "\"" :patterns (make-tm-patterns))
              (make-tm-match "(,)#"
                             :captures (vector nil (make-tm-name
                                                    'syntax-builtin-attribute)))
              (make-tm-match "," :name 'syntax-builtin-attribute)
              (make-tm-url))))

(defvar *csv-syntax-table*
  (let ((table (make-syntax-table :string-quote-chars '(#\")))
        (tmlanguage (make-tmlanguage-csv)))
    (set-syntax-parser table tmlanguage)
    table)
  "Syntax table for CSV mode.")

(define-major-mode csv-mode language-mode
    (:name "CSV"
     :description "Major mode for comma-separated-value files."
     :keymap *csv-mode-keymap*
     :syntax-table *csv-syntax-table*
     :mode-hook *csv-mode-hook*)
  (setf (variable-value 'enable-syntax-highlight) t
        (variable-value 'line-wrap) nil))

(define-file-type ("csv") csv-mode)

;;; Minor Mode: csv-rainbow-mode

(defparameter *csv-rainbow-attributes*
  #(syntax-keyword-attribute
    syntax-type-attribute
    syntax-variable-attribute
    syntax-constant-attribute)
  "Themed attributes cycled through by column, in column order.
It leaves out the colors csv-mode already uses: the separator
(`syntax-builtin-attribute'), quoted values (`syntax-string-attribute'),
URLs (`syntax-function-name-attribute') and comments
(`syntax-comment-attribute').  `csv-color-line' tells those apart from
column colors by attribute, so none of them may appear here.")

(defun csv-column-attribute (column)
  "Return the attribute symbol for the 0-based COLUMN, cycling the palette."
  (aref *csv-rainbow-attributes*
        (mod column (length *csv-rainbow-attributes*))))

(defun csv-move-to-record-start (point)
  "Move POINT up to the first line of the record that contains it.
A line continues the previous one when that line ended inside a quoted
value, which Lem records as the previous line's syntax context."
  (loop :for previous := (line-previous (point-line point))
        :while (and previous (line-syntax-context previous))
        :do (line-offset point -1)))

(defun csv-keep-color-p (point charpos)
  "True if the character CHARPOS into POINT's line is a quoted value, URL or
comment.  POINT must be at the start of its line.  Those characters keep the
colors csv-mode gave them, so rainbow mode leaves them alone."
  (member (text-property-at point :attribute charpos)
          '(syntax-string-attribute
            syntax-function-name-attribute
            syntax-comment-attribute)))

(defun csv-color-line (point in-quote column)
  "Color the line at POINT field by field, and return the state after it.
IN-QUOTE says whether the line starts inside a quoted value, and COLUMN is
the 0-based column it starts in.  A field takes its column's color, except
for quoted values and URLs, which keep csv-mode's colors, and a separator
keeps the separator color.  Return (values IN-QUOTE COLUMN) for the next
line: the same state if a quoted value continues, otherwise not in a quote
and column 0. A comment line is skipped, since its commas and quotes are
text, and it ends the record like any other line."
  (when (and (not in-quote)
             (plusp (length (line-string point)))
             (eq (text-property-at point :attribute 0)
                 'syntax-comment-attribute))
    (return-from csv-color-line (values nil 0)))
  (let* ((string (line-string point))
         (length (length string))
         (field-start 0)
         (i 0))
    (labels ((paint (from to attribute)
               (when (< from to)
                 (with-point ((a point)
                              (b point))
                   (line-offset a 0 from)
                   (line-offset b 0 to)
                   (put-text-property a b :attribute attribute))))
             (paint-field (from to)
               (let ((run-start nil))
                 (loop :for j :from from :below to
                       :do (cond ((csv-keep-color-p point j)
                                  (when run-start
                                    (paint run-start j
                                           (csv-column-attribute column))
                                    (setf run-start nil)))
                                 ((null run-start)
                                  (setf run-start j))))
                 (when run-start
                   (paint run-start to (csv-column-attribute column))))))
      (loop
        (when (>= i length)
          (return))
        (let ((char (char string i)))
          (cond (in-quote
                 (when (char= char #\")
                   (if (and (< (1+ i) length)
                            (char= (char string (1+ i)) #\"))
                       (incf i)
                       (setf in-quote nil))))
                ((char= char #\")
                 (setf in-quote t))
                ((char= char #\,)
                 (paint-field field-start i)
                 (paint i (1+ i) 'syntax-builtin-attribute)
                 (setf field-start (1+ i))
                 (incf column))))
        (incf i))
      (paint-field field-start length))
    (if in-quote
        (values t column)
        (values nil 0))))

(defun csv-color-columns (start end)
  "Color each field of the lines from START to END by its column.
Runs after Lem's own syntax scan, so it replaces the colors that scan put on
the text.  Does nothing unless the buffer is in csv-mode with
csv-rainbow-mode on."
  (let ((buffer (point-buffer start)))
    (when (and (eq (buffer-major-mode buffer) 'csv-mode)
               (mode-active-p buffer 'csv-rainbow-mode))
      (with-point ((point start)
                   (limit end))
        (line-start point)
        (line-end limit)
        (csv-move-to-record-start point)
        (let ((in-quote nil)
              (column 0))
          (loop
            (multiple-value-setq (in-quote column)
              (csv-color-line point in-quote column))
            (unless (and (line-offset point 1)
                         (point<= point limit))
              (return))))))))

(defun csv-rainbow-rescan ()
  "Re-scan the whole current buffer so a change of rainbow mode shows.
Lem's scan clears each line's colors before applying them, so turning the
mode off restores the normal highlighting."
  (let ((buffer (current-buffer)))
    (syntax-scan-region (buffer-start-point buffer)
                        (buffer-end-point buffer))))

(define-minor-mode csv-rainbow-mode
    (:name "Rainbow"
     :description "Color each CSV column with its own color."
     :enable-hook 'csv-rainbow-rescan
     :disable-hook 'csv-rainbow-rescan))

(add-hook (variable-value 'after-syntax-scan-hook :global)
          'csv-color-columns)
