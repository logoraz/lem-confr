(defpackage #:lem-confr/keybindings
  (:use #:cl #:lem)
  (:import-from #:lem-core/commands/file
                #:find-file-recursively)
  (:import-from #:lem-lisp-mode
                #:lisp-apropos-package)
  (:import-from #:lem-confr/commands
                #:stack-window-layout)
  (:documentation "General place for altered default keybindings."))

(in-package #:lem-confr/keybindings)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; General Keybindings
;; Make undo & redo what I am used to
(defun custom-keybindings ()
  "Defining in a function to re-deploy after starting lem/legit after init."
  (define-key *global-keymap* "C-/" 'undo)
  (define-key *global-keymap* "C-_" 'redo)

  ;; Hack Alt "M-" key doesn't seem to work for lem on Fedora 42...
  ;; see https://github.com/lem-project/lem/pull/1811
  ;; Added fix to lem/frontends/sdl2/keyboard.lisp
  (define-key *global-keymap* "C-;" 'execute-command) ;; Alternative keybinding for `M-x'
  
  (define-key *global-keymap* "C-h B" 'describe-bindings)
  (define-key *global-keymap* "C-h k" 'describe-key)
  (define-key *global-keymap* "C-h a" 'apropos-command)
  (define-key *global-keymap* "C-h p" 'lisp-apropos-package)
  (define-key *global-keymap* "C-x F" 'find-file-recursively)

  ;; tabbar keybindings
  (define-key *global-keymap* "C-c j" 'lem/tabbar::tabbar-next)
  (define-key *global-keymap* "C-c k" 'lem/tabbar::tabbar-prev)

  ;; My own commands
  (define-key *global-keymap* "C-c s" 'stack-window-layout))

(custom-keybindings) ; Enable custom keybindings on initialization.

