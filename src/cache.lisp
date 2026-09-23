(defpackage #:lem-confr/cache
  (:use #:cl #:lem)
  (:export #:redirect-debug-log
           #:redirect-history
           #:redirect-listener-history
           #:redirect-settings
           #:clear-confr-logs
           #:clear-lem-cache
           #:redirect-tutor-saves)
  (:documentation "Redirect Lem's debug & history cache."))

(in-package #:lem-confr/cache)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Lem Cache Redirection 
;;; (should NOT be VOMITED in the user config directory)
;;; Instead should be put in XDG_CACHE_HOME where cache should live!
;;; Why they chose to copy Emacs on this front baffles me...

(defun redirect-listener-history ()
  "Redirect lem's lisp-repl history from ~/.config/lem/history/ to ~/.cache/lem/history/
by redefining start-listener-mode to redirect its pathname argument."
  (sb-ext:without-package-locks
    (defun lem/listener-mode:start-listener-mode (&optional history-pathname)
      (when history-pathname
        (setf history-pathname
              (merge-pathnames (file-namestring history-pathname)
                               (uiop:xdg-cache-home "lem/history/"))))
      (lem/listener-mode::listener-mode t)
      (unless (lem/listener-mode::listener-history (current-buffer))
        (setf (lem/listener-mode::listener-history (current-buffer))
              (lem/common/history:make-history :pathname history-pathname))
        (add-hook (variable-value 'kill-buffer-hook :buffer (current-buffer))
                  'lem/listener-mode::save-history))
      (add-hook *exit-editor-hook* 'lem/listener-mode::save-all-histories)
      (unless (lem/listener-mode::input-start-point (current-buffer))
        (lem/listener-mode::change-input-start-point (current-point))))))


(defun redirect-history ()
  "Redirect lem's history files from ~/.config/lem/history/ to 
~/.cache/lem/history/."
  (let ((cache-history (uiop:xdg-cache-home "lem/history/")))
    (ensure-directories-exist cache-history)
    (setf lem-core/commands/file::*files-history*
          (lem/common/history:make-history
           :pathname (merge-pathnames "files" cache-history)
           :limit lem-core/commands/file::*file-history-limit*))
    (setf lem-core/commands/other::*commands-history*
          (lem/common/history:make-history
           :pathname (merge-pathnames "commands" cache-history)
           :limit lem-core/commands/other::*history-limit*))))

(defun redirect-debug-log ()
  "Redirect lem's debug.log from ~/.config/lem/ to ~/.cache/lem/logs/.
Reconfigures log4cl, closing the old appender and opening the new one,
then deletes the stray file left behind by lem's initial launch call."
  (let ((log-path (uiop:xdg-cache-home "lem/logs/debug.log")))
    (ensure-directories-exist log-path)
    (log:config :sane :daily log-path :info)
    (uiop:delete-file-if-exists (merge-pathnames "debug.log" (lem-home)))))


(defun redirect-settings ()
  "Redirect lem's settings.sexp from ~/.config/lem/ to ~/.cache/lem/settings.sexp
by redefining config-pathname to merge with XDG_CACHE_HOME instead of lem-home."
  (sb-ext:without-package-locks
    (defun lem-core::config-pathname ()
      (merge-pathnames lem-core::*config-file-name*
                       (uiop:xdg-cache-home "lem/")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Lem Cache Redirection 

(defun clear-confr-logs ()
  "Recursively delete $XDG_CONFIG_HOME/lem/logs/ (confr-error.log,
confr-startup.log), then recreate the empty directory."
  (let ((logs-dir (uiop:xdg-config-home "lem/logs/")))
    (when (probe-file logs-dir)
      (uiop:delete-directory-tree logs-dir :validate t))
    (ensure-directories-exist logs-dir)))

(defun clear-lem-cache ()
  "Recursively delete everything under $XDG_CACHE_HOME/lem/, then recreate
the empty directory so history/debug.log/settings.sexp writes still succeed."
  (let ((cache-dir (uiop:xdg-cache-home "lem/")))
    (when (probe-file cache-dir)
      (uiop:delete-directory-tree cache-dir :validate t))
    (ensure-directories-exist cache-dir)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Lem Tutorial Saves Redirection

(defun redirect-tutor-saves ()
  "Redirect lem-tutor's save/progress files from ~/.config/lem/lem-tutor-saves/
to ~/.cache/lem/lem-tutor-saves/ by redefining tutorial-save-file and
tutorial-progress to merge with XDG_CACHE_HOME instead of lem-home."
  (sb-ext:without-package-locks
    (defun lem-tutor::tutorial-save-file ()
      (merge-pathnames "lem-tutor-saves/lem-tutor-save.txt"
                       (uiop:xdg-cache-home "lem/")))
    (defun lem-tutor::tutorial-progress ()
      (merge-pathnames "lem-tutor-saves/lem-tutor-progress.lisp"
                       (uiop:xdg-cache-home "lem/")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Apply

(redirect-debug-log)
(redirect-history)
(redirect-listener-history)
(redirect-settings)
(redirect-tutor-saves)