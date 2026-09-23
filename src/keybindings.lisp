(defpackage #:lem-confr/keybindings
  (:use #:cl #:lem)
  (:import-from #:lem-core/commands/file
                #:find-file-recursively)
  (:import-from #:lem-lisp-mode
                #:lisp-apropos-package)
  (:import-from #:lem/filer
                #:*filer-mode-keymap*)
    (:import-from #:lem-confr/commands
                #:stack-window-layout
                #:lem-confr-clear-logs
                #:lem-confr-clear-cache
                #:lem-confr-filer-refresh)
  (:documentation "General place for altered default keybindings."))

(in-package #:lem-confr/keybindings)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; General Keybindings

(defun custom-keybindings ()
  "Defining in a function to re-deploy after starting lem/legit after init."

  ;; Make undo & redo what I am used to
  (define-key *global-keymap* "C-/" 'undo)
  (define-key *global-keymap* "C-_" 'redo)
  (define-key *global-keymap* "C-;" 'execute-command) ;; Alternative keybinding for `M-x'
  
  (define-key *global-keymap* "C-h B" 'describe-bindings)
  (define-key *global-keymap* "C-h k" 'describe-key)
  (define-key *global-keymap* "C-h a" 'apropos-command)
  (define-key *global-keymap* "C-h p" 'lisp-apropos-package)
  (define-key *global-keymap* "C-x F" 'find-file-recursively)
  (define-key *global-keymap* "C-c e" 'lisp-eval-clear)

  ;; tabbar keybindings
  (define-key *global-keymap* "C-c j" 'lem/tabbar::tabbar-next)
  (define-key *global-keymap* "C-c k" 'lem/tabbar::tabbar-prev)

  ;; Custom Commands
  (define-key *global-keymap* "C-c s" 'stack-window-layout)
  (define-key *global-keymap* "C-c l" 'lem-confr-clear-logs)
  (define-key *global-keymap* "C-c C-l" 'lem-confr-clear-cache)
  (define-key *filer-mode-keymap* "g" 'lem-confr-filer-refresh)

  ;; Todo
  )

(custom-keybindings) ; Enable custom keybindings on initialization.

