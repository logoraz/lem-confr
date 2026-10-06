(uiop:define-package :csv-mode
  (:use :cl)
  (:import-from :lem
                #:define-file-type
                #:define-major-mode
                #:enable-syntax-highlight
                #:make-syntax-table
                #:make-tm-match
                #:make-tm-patterns
                #:make-tmlanguage
                #:set-syntax-parser
                #:syntax-builtin-attribute
                #:syntax-function-name-attribute
                #:variable-value)
  (:import-from :lem/language-mode
                #:language-mode)
  (:import-from :lem/language-mode-tools
                #:make-tm-string-region)
  (:export :*csv-mode-hook*
           :csv-mode)
  (:documentation "CSV file syntax highlighting"))
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
  "Return the tmlanguage for CSV: quoted values, field separators and URLs.
A quoted value is a region from one double quote to the next, so it spans
lines.  A doubled quote inside it closes and reopens the region, which
looks identical.  Commas inside a quoted value belong to the region, so
they are never matched as separators.  URLs are highlighted in plain
fields and, as an inner rule, inside quoted values."
  (make-tmlanguage
   :patterns (make-tm-patterns
              (make-tm-string-region "\"" :patterns (make-tm-patterns
                                                     (make-tm-url)))
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
  (setf (variable-value 'enable-syntax-highlight) t))

(define-file-type ("csv") csv-mode)
