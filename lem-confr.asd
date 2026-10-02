(defsystem "lem-confr"
  :description "Modular Lem Configuration."
  :author "Erik P Almaraz"
  :license "LGPL-2.1-only WITH LLGPL"
  :version (:read-file-form "version.sexp" :at (0 1))
  :depends-on ("local-time")
  :components ((:module "lib"
                :pathname "code/lib"
                :components ((:file "syntax")
                             (:file "utilities")))
               (:module "base"
                :pathname "code/base"
                :depends-on ("lib")
                :components ((:file "cache")
                             (:file "appearance")
                             (:file "completions")
                             (:file "editing")
                             (:file "filer")
                             (:file "lisp-ide")
                             (:file "grafts")))
               (:module "interface"
                :pathname "code"
                :depends-on ("lib" "base")
                :components ((:file "commands")
                             (:file "keybindings")
                             (:file "scratch"))))
  :long-description "
Modular Lem configuration scaffolded as its own system.

Bootstrapped from init.lisp, which loads lem-confr defensively: failures areg
logged rather than left to block Lem from starting, so a broken edit during
config development can be diagnosed from within Lem itself, without having
to chase it down in a terminal.

Modules/Packages:
  - syntax: lem-confr Macros/Syntax Extensions
  - utilities: Helper functions and common utilities
  - cache: redirects Lem's poorly mapped cache to XDG_CACHE_HOME/lem/*
  - appearance: Theme, colors, UI customization
  - completions: Completion system configuration
  - editing: General text-editing behavior
  - filer: Filer extensions --> dired-like
  - lisp-ide: Common Lisp IDE enhancements
  - commands: Custom Lem commands
  - keybindings: Key binding configuration
  - grafts: Patches/Grafts for confirmed upstream Lem Bugs
  - scratch: Scratch code space for testing Lisp constructs.
")
