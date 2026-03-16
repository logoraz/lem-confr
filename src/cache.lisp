(defpackage #:lem-confr/cache
  (:use #:cl #:lem)
  (:export #:redirect-debug-log
           #:redirect-history
           #:redirect-listener-history)
  (:documentation "Redirect Lem's debug & history cache."))

(in-package #:lem-confr/cache)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Lem Cache Redirection 
;;; (should NOT be vomited in the user config directory)
;;; instead should be put in XDG_CACHE_HOME where cache should live...
;;; not sure why they did it this way...
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Apply
(redirect-debug-log)
(redirect-history)
(redirect-listener-history)
