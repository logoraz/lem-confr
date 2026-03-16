(defpackage #:lem-confr/commands
  (:use #:cl #:lem)
  (:import-from #:lem-core/commands/window
                #:split-active-window-horizontally
                #:split-active-window-vertically
                #:next-window)
  (:import-from #:local-time
                #:format-timestring
                #:now)
  (:export #:stack-window-layout
           #:open-init-file
           #:*time-stamp-format*
           #:time-stamp)
  (:documentation "Custom commands."))

(in-package #:lem-confr/commands)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Window Layouts
;; src/commands/window.lisp
(define-command stack-window-layout () ()
  (split-active-window-horizontally)
  (next-window)
  (split-active-window-vertically))

#+(or)
(define-command project-window-layout () ()
  (lem/filer::filer))
#+(or)
(define-key *global-keymap* "C-c s" 'stack-window-layout)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Basics Commands
(define-command open-init-file () ()
  (find-file
   (merge-pathnames "init.lisp" (lem-home))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Time Stamps
(defvar *time-stamp-format*
  ;; Equals Emacs org-mode's default format.
  '("<" :year "-" (:month 2) "-" (:day 2) " " :short-weekday ">")
  "Time-stamp format.
  By default, prints year, month, day, and short english day: \"<2023-07-05 Wed>\"")

(defun format-time-stamp (&key (day (now)) (stream nil))
  (format-timestring stream day :format *time-stamp-format*))

(define-command time-stamp () ()
  "Print a timestamp of today, in the form <2042-12-01 Mon>."
  (insert-string (current-point) (format-time-stamp :stream t)))

