# lem-confr - Modular Lem Configuration

<p align="center">
  <img src="assets/cl-logoraz.svg" height="150" hspace="15" align="absmiddle" />
  <img src="assets/lem.svg" height="150" hspace="15" align="absmiddle" />
</p>

Modular configuration for Lem (Common Lisp Editor/IDE).

This configuration is set up as its own Common Lisp System `lem-confr`!

Stages convenient error logging, allowing the config to fail *quietly* and
and generates `*.log` files in `lem/logs/` (each log entry is timestamped): 
- `confr-error.log` → lists any issues encounted upon loading `lem-confr` system,
- `confr-startup.log` → lists successful startup.


## System Scaffold

| Path            | Description                                             |
|-----------------|---------------------------------------------------------|
| `init.lisp`     | User init; bootstraps loading of the `lem-confr` system |
| `lem-confr.asd` | System definition for this configuration                |
| `src/`          | Source files for this configuration                     |
| `contrib/`      | WIP — prototype Lem extension systems                   |
| `assets/`       | Images, `lem.desktop`, and related files                |
| `files/`        | CL system (and other) files staged for deployment       |
| `logs/`         | Where `lem-confr`'s logger stores its logs              |

### `src/` Modules

| Module        | Description                                      |
|---------------|--------------------------------------------------|
| `utilities`   | Helper functions and common utilities            |
| `cache`       | Redirects Lem's cache to `$XDG_CACHE_HOME/lem/*` |
| `appearance`  | Theme, colors, UI customization                  |
| `completions` | Completion system configuration                  |
| `lisp-ide`    | Common Lisp IDE enhancements                     |
| `commands`    | Custom Lem commands                              |
| `keybindings` | Key binding configuration                        |
| `bug-fixes`   | Patches for confirmed upstream Lem bugs          |


## Setup
Clone this repo and place in $XDG_CONFIG_HOME:

```bash
  $ cd ~/.config/
  $ git clone https://github.com/logoraz/lem-confr.git lem
```


## TODOs (Wish List)
- Still have yet to think of something I want to build for Lem...


## References
- lem source: https://github.com/lem-project/lem
- General configuration layout inspirations:
  - https://github.com/garlic0x1/.lem/
  - https://github.com/fukamachi/.lem
- Paredit configuration inspiration:
  - https://github.com/Gavinok/.lem


## License
```lisp
(defmacro license-terms (system . plist)
  "See LICENSE for the actual legally-binding, non-parenthesized version."
  (declare (optimize (safety 0))) ; use at your own risk
  `(list :system ',system ,@plist))

(license-terms lem-confr
  :type        '(:mit . "https://opensource.org/licenses/MIT")
  :permissions '(:use :copy :modify :merge :publish :distribute :sublicense :sell)
  :conditions  '(:include-copyright-notice)
  :warranty    nil)
```

↳ [LICENSE](LICENSE)
