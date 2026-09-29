(defpackage #:lem-confr/scratch
  (:use #:cl #:lem)
  (:import-from #:local-time
                #:now
                #:timestamp-year
                #:timestamp-month
                #:timestamp-day)
  (:export #:insert-julian-date-code)
  (:documentation "Scratch code space for testing Lisp constructs."))

(in-package #:lem-confr/scratch)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Julian Date/Time Stamp Generator

(defun julian-day (year month day)
  "Return the day of year (1-366) for YEAR, MONTH, DAY."
  (let ((days #(31 28 31 30 31 30 31 31 30 31 30 31))
        (leap (and (zerop (mod year 4))
                   (or (plusp (mod year 100)) (zerop (mod year 400))))))
    (+ (loop :for m :below (1- month)
             :sum (svref days m)
             :when (and leap (= m 1)) :sum 1)
       day)))

(defun julian-date-code (year month day)
  "Return the YYDDD Julian code string for YEAR, MONTH, DAY."
  (format nil "~2,'0D~3,'0D" (mod year 100) (julian-day year month day)))

(defun current-julian-date-code ()
  "Return today's Julian date code."
  (let ((current (now)))
    (julian-date-code (timestamp-year current)
                      (timestamp-month current)
                      (timestamp-day current))))

(define-command insert-julian-date-code (&optional arg) (:universal-nil)
  "Insert today's Julian date code (YYDDD) at point. With a universal
argument, prompt for year, month, and day instead."
  (let ((code (if arg
                  (julian-date-code (parse-integer (prompt-for-string "Year: "))
                                    (parse-integer (prompt-for-string "Month: "))
                                    (parse-integer (prompt-for-string "Day: ")))
                  (current-julian-date-code))))
    (insert-string (current-point) code)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; TODO
