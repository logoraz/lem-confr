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

### `lib` (`code/lib`) Module

| Module      | Description                           |
|-------------|---------------------------------------|
| `syntax`    | (WIP) Macros & Syntax Extensions      |
| `utilities` | Helper functions and common utilities |


### `base` (`code/base`) Module

| Module        | Description                                      |
|---------------|--------------------------------------------------|
| `cache`       | Redirects Lem's cache to `$XDG_CACHE_HOME/lem/*` |
| `appearance`  | Theme, colors, UI customization                  |
| `completions` | Completion system configuration                  |
| `editing`     | General text-editing behavior                    |
| `filer`       | Filer extension → dired                          |
| `lisp-ide`    | Common Lisp IDE enhancements                     |
| `grafts`      | Patches/Grafts for confirmed upstream Lem bugs   |


### `interface` (`code`) top-level Module

| Module        | Description                                    |
|---------------|------------------------------------------------|
| `commands`    | Custom Lem commands                            |
| `keybindings` | Key binding configuration                      |
| `scratch`     | Scratch code space for testing Lisp constructs |

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

(license-terms cl-hvec
  :type        '(:|LGPL-2.1-only WITH LLGPL| . "https://spdx.org/licenses/LLGPL.html")
  :permissions '(:use :copy :modify :distribute :link)
  :conditions  '(:include-copyright-notice
                 :disclose-source-lib
                 :same-license-lib
                 :state-changes
                 :lisp-linking)
  :warranty    nil)
```

↳ [LICENSE](LICENSE)
