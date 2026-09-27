(defpackage #:confr-md-table
  (:use #:cl #:lem)
  (:export #:confr-markdown-tab))

(in-package #:confr-md-table)

(define-key lem-markdown-mode::*markdown-mode-keymap* "Tab" 'confr-markdown-tab)

(defun table-row-string-p (line)
  "True if LINE looks like a markdown table row: starts and ends with |."
  (let ((trimmed (string-trim '(#\space #\tab) line)))
    (and (>= (length trimmed) 2)
         (char= (char trimmed 0) #\|)
         (char= (char trimmed (1- (length trimmed))) #\|))))

(defun separator-row-string-p (line)
  "True if LINE is a table's separator row: only |, -, :, whitespace."
  (and (table-row-string-p line)
       (every (lambda (c) (find c ":-| 	")) line)))

(defun split-on-char (string char)
  "Split STRING on CHAR."
  (loop :with start = 0
        :for pos = (position char string :start start)
        :collect (subseq string start (or pos (length string)))
        :while pos
        :do (setf start (1+ pos))))

(defun split-row-cells (line)
  "Split a table row LINE into trimmed cell contents, dropping the
empty pieces produced by its leading/trailing pipes."
  (let* ((trimmed (string-trim '(#\space #\tab) line))
         (inner (subseq trimmed 1 (1- (length trimmed)))))
    (mapcar (lambda (c) (string-trim '(#\space #\tab) c))
            (split-on-char inner #\|))))

(defun table-bounds (point)
  "Return (values start-point end-point) spanning the contiguous block
of table-row lines containing POINT, or NIL if POINT isn't on one."
  (unless (table-row-string-p (line-string point))
    (return-from table-bounds nil))
  (with-point ((start point :temporary)
               (end point :temporary))
    (loop :while (and (line-offset start -1)
                      (table-row-string-p (line-string start))))
    (unless (table-row-string-p (line-string start))
      (line-offset start 1))
    (loop :while (and (line-offset end 1)
                      (table-row-string-p (line-string end))))
    (unless (table-row-string-p (line-string end))
      (line-offset end -1))
    (values (line-start start) (line-end end))))

(defun column-widths (row-lines)
  "Max cell width per column, across the non-separator rows."
  (let* ((content-rows (mapcar #'split-row-cells
                               (remove-if #'separator-row-string-p row-lines)))
         (n (reduce #'max content-rows :key #'length :initial-value 0)))
    (loop :for col :below n
          :collect (reduce #'max content-rows
                           :key (lambda (cells) (length (or (nth col cells) "")))
                           :initial-value 0))))

(defun format-row (line widths)
  "Reformat one table row LINE to the target column WIDTHS."
  (if (separator-row-string-p line)
      (format nil "|~{~A|~}"
              (mapcar (lambda (w) (make-string (+ w 2) :initial-element #\-))
                      widths))
      (format nil "|~{ ~A |~}"
              (loop :for width :in widths
                    :for i :from 0
                    :for cell = (or (nth i (split-row-cells line)) "")
                    :collect (concatenate 'string cell
                                          (make-string (- width (length cell))
                                                       :initial-element #\space))))))

(defun format-table-at-point (point)
  "Reformat the markdown table under POINT to consistent column widths."
  (multiple-value-bind (start end) (table-bounds point)
    (unless start
      (editor-error "Not in a markdown table"))
    (let* ((row-lines (split-on-char (points-to-string start end) #\Newline))
           (widths (column-widths row-lines))
           (new-text (format nil "~{~A~^~%~}"
                             (mapcar (lambda (line) (format-row line widths))
                                     row-lines))))
      (delete-between-points start end)
      (insert-string start new-text))))

(define-command confr-markdown-tab () ()
  "In a markdown table, reformat it. Otherwise, fall through to the
mode's normal Tab behavior."
  (if (table-row-string-p (line-string (current-point)))
      (format-table-at-point (current-point))
      (lem/language-mode::fold-or-indent-or-complete)))