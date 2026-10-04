(defpackage #:lem-confr/init
  (:use #:cl #:lem)
  (:import-from #:local-time
                #:+iso-8601-format+
                #:now
                #:format-timestring)
  (:documentation "lem-confr System Initialization."))

(in-package #:lem-confr/init)

;;; Code:


;;; Bootstrap & Configuration

(defparameter *ocicl-root* (uiop:xdg-cache-home "lem/")
  "Directory holding ocicl's ocicl/ tree and ocicl.csv; installs land here.")

(defun pin-lem-image-systems ()
  "Mark every system already loaded in this Lem image as immutable.
ASDF then never reloads or recompiles them from ocicl's duplicate
copies (alexandria, closer-mop), so only genuinely new libraries build."
  (map nil 'asdf:register-immutable-system (asdf:already-loaded-systems)))

(defun setup-asdf-environment ()
  "Prepare ASDF to load lem-confr and its ocicl-installed dependencies.
Order matters: the ocicl runtime hooks into ASDF's system search, so it
loads before the registry and output-translation steps."
  ;; sb-concurrency is an SBCL contrib — require, not ASDF, avoids ocicl's
  ;; searcher trying to download it as a third-party system
  #+sbcl
  (require :sb-concurrency)

  ;; Tested at run time: a #-ocicl conditional here would be evaluated
  ;; when this DEFUN is read, before the runtime has been loaded
  (unless (find-package "OCICL-RUNTIME")
    (let ((runtime (uiop:xdg-data-home "ocicl/ocicl-runtime.lisp")))
      (when (probe-file runtime)
        (load runtime))))

  ;; with-current-directory below fails if the root doesn't exist yet
  (ensure-directories-exist *ocicl-root*)

  ;; Source registry: recursively discover any .asd under ~/.config/lem/
  ;; and under the ocicl root
  (asdf:initialize-source-registry
   (list :source-registry
         (list :tree (uiop:xdg-config-home "lem/"))
         (list :tree *ocicl-root*)
         :inherit-configuration))

  ;; Output translations: compiled fasls go to XDG_CACHE_HOME, never
  ;; beside source (source may live somewhere read-only, e.g. Guix store)
  (ensure-directories-exist (uiop:xdg-cache-home "common-lisp/"))
  (asdf:initialize-output-translations
   (list :output-translations
         :enable-user-cache
         :inherit-configuration)))


;;; Logging Facilities

(defun current-time ()
  "Emits an ISO 8601 timestamp, with error handling."
  (handler-case
      (format-timestring nil (now) :format +iso-8601-format+)
    (error (condition)
      (format nil "??? (error getting time: ~A)" condition))))

(defparameter *log-separator* (make-string 79 :initial-element #\-))

(defun save-log-file (pathspec kind output)
  "Append a formatted log entry. KIND is :startup or :error."
  (handler-case
      (let ((path (uiop:xdg-config-home pathspec))
            (output (string-right-trim '(#\Newline #\Return #\Space) output)))
        (ensure-directories-exist path)
        (with-open-file (strm path
                              :direction :output
                              :if-exists :append
                              :if-does-not-exist :create
                              :external-format :utf-8)
          (format strm "[~A] ~A~%~A~%~%~A~%"
                  (current-time)
                  (ecase kind (:startup "STARTUP") (:error "ERROR"))
                  output
                  *log-separator*))
        t)
    (file-error (condition)
      (format t "File error while saving log ~A: ~A~%" pathspec condition)
      nil)
    (error (condition)
      (format t "Unexpected error while saving log ~A: ~A~%" pathspec condition)
      nil)))


;;; Load System

(let ((compiler-output (make-string-output-stream))
      (start (get-internal-real-time)))
  (handler-case
      (let ((*error-output*
              (make-broadcast-stream *error-output* compiler-output))
            (*standard-output*
              (make-broadcast-stream *standard-output* compiler-output)))
        (pin-lem-image-systems)
        (setup-asdf-environment)
        (uiop:with-current-directory (*ocicl-root*)
          (asdf:load-system :lem-confr))
        (save-log-file
         "lem/logs/confr-startup.log" :startup
         (format nil "lem-confr v~A loaded in ~,3Fs"
                 (asdf:component-version (asdf:find-system :lem-confr))
                 (/ (- (get-internal-real-time) start)
                    internal-time-units-per-second)))
        (message "lem-confr loaded successfully"))
    (error (condition)
      (save-log-file
       "lem/logs/confr-error.log" :error
       (format nil "~A~%~%--- Compiler output ---~%~A"
               condition
               (get-output-stream-string compiler-output)))
      (message "Warning: lem-confr failed to load - continuing with defaults"))))
