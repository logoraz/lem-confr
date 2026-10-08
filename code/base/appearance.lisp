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

;; Inconsolata: 0.5 em advance, so size 14 gives an exact 7 px cell (0% squeeze).
(set-font :name "Inconsolata" :size 18)

;; Fira Code Light: 0.6 em advance, so size 15 gives an exact 9 px cell (0% squeeze).
#+nil (set-font :name "Fira Code Light" :size 15)

;; Kawkab Mono Light: 0.7 em advance, so size 13 gives a 9 px cell (1.1% squeeze).
#+nil (set-font :name "Kawkab Mono Light" :size 13)


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
