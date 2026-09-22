# lem-confr - Modular Lem Configuration

<p align="center">
  <img src="assets/cl-logoraz.svg" width="200" />
  <img src="assets/lem.svg" width="175" />
</p>

Modular configuration for Lem (Common Lisp Editor/IDE).

This configuration is set up as its own Common Lisp system `lem-confr`!

Stages convenient error logging, allowing the config to fail *quietly* and
and generates `*.log` files in `lem/logs/` (each log entry is timestamped): 
- `confr-error.log` lists any issues encounted upon loading `lem-confr` system,
- `confr-startup.log` lists successful startup.


## System Scaffold

- `init.lisp`     --> User init, bootstrap to load `lem-confr` system
- `lem-confr.asd` --> System definition for this configuration
- `src/`          --> Contains source files for this configuration
- `contrib/`      --> WIP where protype lem extension systems will be held
- `assets/`       --> Where images, lem.desktop, and related stuff are held
- `files/`        --> Where CL system (and other) files are stored for deployment
- `logs/`         --> Where logger stores `lem-confr` system logs


## Setup

Clone this repo and place in $XDG_CONFIG_HOME:

```bash
  $ cd ~/.config/
  $ git clone https://github.com/logoraz/lem-confr.git lem
```


## TODOs (Wish List)

  - Build out more personal keybindings
  - Enable other SLIME for other CL Implementations (e.g. clasp)
  - Build an extension analogous to Emacs' erc-mode

## References:

  - lem source: https://github.com/lem-project/lem
  - General configuration layout inspirations:
    - https://github.com/garlic0x1/.lem/
    - https://github.com/fukamachi/.lem
  - Paredit configuration inspiration:
    - https://github.com/Gavinok/.lem
  