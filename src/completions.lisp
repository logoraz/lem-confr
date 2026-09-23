(defpackage #:lem-confr/completions
  (:use #:cl #:lem)
  (:import-from #:lem-core)
  (:import-from #:lem/prompt-window)
  (:documentation "Completions framework."))

(in-package #:lem-confr/completions)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Completions
;;;

#+(or)
(progn
  ;;; Choose the position of the completion prompt (new in May, 2024)
  (setf lem-core::*default-prompt-gravity* :bottom-display)
  (setf lem/prompt-window::*prompt-completion-window-gravity* :horizontally-above-window)
  (setf lem/prompt-window::*fill-width* t)

  ;; Show the completion list directly, without a first press on TAB:
  (add-hook *prompt-after-activate-hook*
            (lambda ()
              (call-command 'lem/prompt-window::prompt-completion nil)))

  (add-hook *prompt-deactivate-hook*
            (lambda ()
              (lem/completion-mode:completion-end))))

;; Experimental
#+(or)
(sb-ext:without-package-locks
  (defun lem-core:prompt-for-buffer (prompt &key default existing (gravity lem-core::*default-prompt-gravity*))
    "Override to pre-fill the default as literal input text, so the
completion popup actually narrows to it instead of just displaying it
as a label the completion mechanism never sees."
    (let ((result (prompt-for-string
                   (if default
                       (format nil "~a(~a) " prompt default)
                       prompt)
                   :initial-value default
                   :completion-function *prompt-buffer-completion-function*
                   :test-function (and existing
                                       (lambda (name)
                                         (or (alexandria:emptyp name)
                                             (get-buffer name))))
                   :history-symbol 'prompt-for-buffer
                   :gravity gravity)))
      (if (string= result "")
          default
          result))))