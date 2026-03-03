# lem-confr - Lem Configuration

<p align="center">
  <img src="assets/cl-logoraz.svg" width="200" />
  <img src="assets/lem.svg" width="200" />
</p>

Modular configuration for Lem (Common Lisp Editor/IDE).

This configuration is set up as its own Common Lisp system `:lem-confr`!

Stages convenient error logging, allowing the config to fail *quietly* and
and generates `*.log` files in `lem/logs/` (each log entry is timestamped): 
- `confr-error.log` lists any issues encounted upon loading, and
- `confr-startup.log` lists successful startup


## System Scaffold

- `basis.lisp`    --> (Optional) Deploy CL rc files ready for ocicl
- `init.lisp`     --> User init, bootstrap to load `:lem-confr'
- `lem-confr.asd` --> System definition for this configuration
- `src/`          --> Contains source files for this configuration
- `contrib/`      --> WIP where protype lem extension systems will be held
- `assets/`       --> Where images, lem.desktop, and related stuff are held


## Setup

This Lem configuration is currently setup through my flake configuration, all 
that is nneded is to clone to `XDG_CONFIG_HOME`:

```bash

  $ cd ~/.config/lem
  $ git clone https://codeberg.org/logoraz/lem-confr.git lem

```


## TODOs (Wish List)

  - Beautify error logging system, make more robust.
    - disable Lem's debug.log's in user config directory!
  - Build out more personal keybindings
  - Build an extension analogous to Emacs' erc-mode


## References:
  - lem source: https://github.com/lem-project/lem
  - General configuration layout inspirations:
    - https://github.com/garlic0x1/.lem/
    - https://github.com/fukamachi/.lem
  - Paredit configuration inspiration:
    - https://github.com/Gavinok/.lem
  - TODO
