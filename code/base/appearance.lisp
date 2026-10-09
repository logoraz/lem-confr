(defpackage #:lem-confr/base/appearance
  (:use #:cl #:lem)
  (:import-from #:lem-core
                #:set-font
                #:cursor
                #:highlight-line-color)
  (:import-from #:lem/line-numbers
                #:line-numbers-attribute
                #:active-line-number-attribute)
  (:import-from #:lem-dashboard
                #:set-default-dashboard
                #:*dashboard-mode-keymap*)
  (:import-from #:lem-lisp-mode
                #:lisp-mode)
  (:import-from #:lem-paredit-mode
                #:paredit-mode)
  (:export #:*confr-fonts*
           #:apply-font)
  (:documentation "Appearance Configuration"))

(in-package #:lem-confr/base/appearance)


;;; Frame Parameters/Transparency
;;;
;;; webkit_web_view_set_background_color only fills in where the page draws
;;; nothing, but editor.js repaints an opaque canvas background every frame, so
;;; no CFFI call can override it. Real transparency needs patching that JS and
;;; rebuilding the Vite bundle — not a Lisp fix


;;; Fonts
;;;
;;; See lem/src/interface.lisp (or lem/src/commands/font.lisp)

(defparameter *confr-fonts*
  '(("JetBrains Mono Light" . 15)
    ("Noto Sans Mono"       . 14)
    ("kawkab Mono Light"    . 13)
    ("Inconsolata"          . 14)
    ("Fira Code Light"      . 15))
  "Alist of (FAMILY . SIZE) pairs. Entries are listed in order of preference.
Each size is an exact or near-exact fit for that font's advance width.")

(defun apply-font (name)
  "Apply the font NAME from `*confr-fonts*', using its paired size.
Do nothing when NAME is not in the list."
  (let ((entry (assoc name *confr-fonts* :test #'string=)))
    (when entry
      (set-font :name (car entry) :size (cdr entry)))))

;; Apply the "default" font at load.
(apply-font (car (first *confr-fonts*)))


;;; Theme Configuration

;; See lem/src/ext/themes.lisp
(load-theme "decaf") ; "lem-default"

;; Set custom Cursor color (variant base0d)
;; https://iamroot.tech/color-picker/default.aspx?color=88a2b7
;; See lem/src/cursors.lisp, lem/src/attribute.lisp
;; See lem/src/line-numbers.lisp, lem/src/ext/themes.lisp,
;; lem/src/highlight-line.lisp
(defvar *lc/default-cursor-color* "#88a2b7")

(define-attribute cursor
  (:light :background "black") ;; TODO |--> Set color for light cursor (default for now)
  (:dark :background *lc/default-cursor-color*))

(define-attribute line-numbers-attribute
  (t :foreground :base02 :background :base00))

(define-attribute active-line-number-attribute
  (t :foreground :base0d :background (highlight-line-color)))


;;; Dashboard

(defvar *lem-confr-splash*
  (list
   (format nil "~{~A~%~}"
           (list
            "                                              "
            "              ####         ----               "
            "          ########         --------           "
            "       ###########         -----------        "
            "     #########        *        ---------      "
            "    #######          ***          -------     "
            "   #######          ******         -------    "
            "  #######             *****         -------   "
            "  ######         ***********         ------   "
            "  ######       ***************       ------   "
            "  #######     *****       *****     -------   "
            "   #######   *****         *****   -------    "
            "    #######                       -------     "
            "     #########                 ---------      "
            "       ###########         -----------        "
            "          ########         --------           "
            "              ####         ----               "
            "                                              "
            "               Welcome to Lem!                "))))


(define-command lisp-scratch-2 () ()
  "Define lisp-scratch buffer that enables lisp & paredit mode straight away!"
  (let ((buffer (primordial-buffer)))
    (change-buffer-mode buffer 'lisp-mode)
    (change-buffer-mode buffer 'paredit-mode t)
    (switch-to-buffer buffer)))

(set-default-dashboard :splash *lem-confr-splash*
                       :project-count 7
                       :file-count 7
                       :hide-links t)

(define-key *dashboard-mode-keymap* "l" 'lisp-scratch-2)


;;; Tabs
;;; Toggle/Disable tabbar

(setf lem/tabbar:*enable-tabbar-on-startup* nil)
