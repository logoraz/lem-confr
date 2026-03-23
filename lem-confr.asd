(defsystem "lem-confr"
  :description "Modular Lem Configuration."
  :author "Erik P Almaraz <erikalmaraz@fastmail.com>"
  :license "MIT"
  :version (:read-file-form "version.sexp" :at (0 1))
  :depends-on ((:feature :sbcl "sb-concurrency"))
  :components
  ((:module "src"
    :components
    ((:file "utilities")
     (:file "cache")
     (:file "appearance")
     (:file "completions")
     (:file "commands" :depends-on ("utilities"))
     (:file "keybindings" :depends-on ("commands"))
     (:file "lisp-ide"  :depends-on ("commands"))
     (:file "playground"))))
  :long-description "
Modular Lem configuration scaffolded as its own system.

Components:
  - cache: redirects Lem's poorly mapped cache to XDG_CACHE_HOME/lem/*
  - utilities: Helper functions and common utilities  
  - appearance: Theme, colors, UI customization
  - completions: Completion system configuration
  - commands: Custom Lem commands
  - keybindings: Key binding configuration
  - lisp-ide: Common Lisp IDE enhancements
  - playground: Experimental features

This system can be loaded independently or as part of Lem's initialization.
")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Secondary Systems
(defsystem "lem-confr/contrib"
  :description "Prototype Lem Extension systems."
  :depends-on ("lem-confr")
  :components
  ((:module "contrib"
    :components
    ((:file "scratch")))))
