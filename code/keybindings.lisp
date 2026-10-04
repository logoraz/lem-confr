(defpackage #:lem-confr/keybindings
  (:use #:cl #:lem)
  (:import-from #:lem-core/commands/file
                #:find-file-recursively)
  (:import-from #:lem-lisp-mode
                #:lisp-apropos-package)
  (:import-from #:lem-lisp-mode/eval
                #:lisp-eval-clear)
  (:import-from #:lem/tabbar
                #:toggle-tabbar
                #:tabbar-next
                #:tabbar-prev)
  (:import-from #:lem/filer
                #:*filer-mode-keymap*)
  (:import-from #:lem-paredit-mode
                #:*paredit-mode-keymap*
                #:paredit-slurp
                #:paredit-barf)
  (:import-from #:lem-markdown-mode
                #:*markdown-mode-keymap*)
  (:import-from #:lem-confr/commands
                #:stack-window-layout
                #:confr-clear-logs
                #:confr-clear-cache
                #:confr-paredit-quotewrap
                #:confr-fill-paragraph
                #:confr-filer-refresh
                #:confr-filer-create-directory)
  (:export #:editing-keybindings
           #:help-keybindings
           #:tabbar-keybindings
           #:paredit-keybindings
           #:confr-keybindings
           #:filer-keybindings)
  (:documentation "General place for altered default keybindings."))

(in-package #:lem-confr/keybindings)


;;; General Keybindings

(defun editing-keybindings ()
  "General editing keybindings: undo/redo, file navigation, and
paragraph manipulation."
  (define-key *global-keymap* "C-/"   'undo)
  (define-key *global-keymap* "C-_"   'redo)
  (define-key *global-keymap* "C-x F" 'find-file-recursively)
  ;; rebind delete-active-window since I want M-q for fill-paragraph
  (define-key *global-keymap* "C-c q" 'delete-active-window)
  (define-key *markdown-mode-keymap* "M-q" 'confr-fill-paragraph))

(defun help-keybindings ()
  "Bindings for describe-bindings, describe-key, apropos-command, and
lisp-apropos-package."
  (define-key *global-keymap* "C-h B" 'describe-bindings)
  (define-key *global-keymap* "C-h k" 'describe-key)
  (define-key *global-keymap* "C-h a" 'apropos-command)
  (define-key *global-keymap* "C-h p" 'lisp-apropos-package))

(defun tabbar-keybindings ()
  "Toggle the tabbar and cycle between tabs."
  (define-key *global-keymap* "C-c o" 'toggle-tabbar)
  (define-key *global-keymap* "C-c j" 'tabbar-next)
  (define-key *global-keymap* "C-c k" 'tabbar-prev))

(defun paredit-keybindings ()
  "Slurp, barf, and quote-wrap bindings for paredit-mode."
  (define-key *paredit-mode-keymap* "Shift-Right" 'paredit-slurp)
  (define-key *paredit-mode-keymap* "Shift-Left" 'paredit-barf)
  (define-key *paredit-mode-keymap* "M-\"" 'confr-paredit-quotewrap))

(defun confr-keybindings ()
  "Bindings for lem-confr's own custom commands: window layout, Lisp
eval-clear, log/cache clearing, and Filer refresh."
  (define-key *global-keymap* "C-c s"   'stack-window-layout)
  (define-key *global-keymap* "C-c e"   'lisp-eval-clear)
  (define-key *global-keymap* "C-c l"   'confr-clear-logs)
  (define-key *global-keymap* "C-c C-l" 'confr-clear-cache))

(defun filer-keybindings ()
  "Bindings for lem-confr's Filer extension."
  (define-key *filer-mode-keymap* "g" 'confr-filer-refresh)
  (define-key *filer-mode-keymap* "+" 'confr-filer-create-directory))


;;; Apply Keybindings

(editing-keybindings)
(help-keybindings)
(tabbar-keybindings)
(paredit-keybindings)
(confr-keybindings)
(filer-keybindings)
