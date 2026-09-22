(defpackage #:lem-confr/init
  (:use #:cl #:lem)
  (:import-from #:local-time
                #:now
                #:format-timestring)
  (:documentation "lem-confr System Initialization."))

(in-package #:lem-confr/init)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; ASDF Registry

(ensure-directories-exist
 (uiop:xdg-cache-home "common-lisp/"))

(asdf:initialize-output-translations
 (list :output-translations
       :enable-user-cache
       :inherit-configuration))

(asdf:initialize-source-registry
 (list :source-registry
       (list :tree (uiop:xdg-config-home "lem/"))
       :inherit-configuration))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Logging Facilities

(defun current-time ()
  "Emits formatted time using local-time, with error handling."
  (handler-case
      (format nil "[~A] "
              (format-timestring nil (now)
                                 :format '(:year "-" :month "-" :day "-T"
                                           :hour ":" :min ":" :sec)))
    (error (condition)
      (format nil "Error getting current time: ~A" condition))))

(defun save-log-file (pathspec output)
  "Save log files for initializing lem-confr, with improved error handling."
  (handler-case
      (let ((path (uiop:xdg-config-home pathspec)))
        (ensure-directories-exist path)
        (with-open-file (strm path
                              :direction :output
                              :if-exists :append
                              :if-does-not-exist :create
                              :external-format :utf-8)
          (format strm "~A Load lem-confr output: ~A~%" (current-time) output))
        t)
    (file-error (condition)
      (format t "File error while saving log ~A: ~A~%" pathspec condition)
      nil)
    (error (condition)
      (format t "Unexpected error while saving log ~A: ~A~%" pathspec condition)
      nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Load System

(handler-case
    (progn
      (sb-ext:without-package-locks
        (asdf:load-system :lem-confr))
      (save-log-file "lem/logs/confr-startup.log" "Success")
      (message "lem-confr loaded successfully"))
  (error (condition)
    (save-log-file "lem/logs/confr-error.log" condition)
    (message "Warning: lem-confr failed to load - continuing with defaults")))
