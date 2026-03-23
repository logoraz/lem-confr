(defpackage #:lem-confr/appearance
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

(in-package #:lem-confr/appearance)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Frame Parameters/Transparency
;; TBD
;; Can't enable transparency or frame/window modifications as webview runs
;; as a separate process and communicates via json-rpc...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Fonts
;; See lem/src/interface.lisp (or lem/src/commands/font.lisp)
(set-font :name "Fira Code Light" :size 13)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Theme
;; See lem/src/ext/themes.lisp
;; https://github.com/lem-project/lem/commit/4d4b4b4e7b366313fd513bf33bcb10c0256ca824
;; Since this commit "lem-default" is buggy and weird things happen
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Dashboard
(defvar *lem-confr-splash* '("
              ####         ----              
          ########         --------          
       ###########         -----------       
     #########        *        ---------     
    #######          ***          -------    
   #######          ******         -------   
  #######             *****         -------  
  ######         ***********         ------  
  ######       ***************       ------  
  #######     *****       *****     -------  
   #######   *****         *****   -------   
    #######                       -------    
     #########                 ---------     
       ###########         -----------       
          ########         --------          
              ####         ----              

               Welcome to Lem!               
"))

(define-command lisp-scratch-2 () ()
  "Define lisp-scratch buffer that enables paredit mode straight away!"
  (let ((buffer (primordial-buffer)))
    (change-buffer-mode buffer 'lisp-mode)
    (change-buffer-mode buffer 'paredit-mode t)
    (switch-to-buffer buffer)))

(set-default-dashboard :splash *lem-confr-splash*
                       :project-count 3
                       :file-count 7
                       :hide-links t)

(define-key *dashboard-mode-keymap* "l" 'lisp-scratch-2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Tabs
;; Tab bar does not update after killing buffers
;; see See https://github.com/lem-project/lem/issues/1993
;; |--> lem/frontends/server/tabbar.lisp (:lem/tabbar)
;; |--> lem/src/commands/file.lisp (:lem-core/commands/file)
;; |--> lem/src/buffer/buffer-ext.lisp (:lem-core)
;; Hack fix
(add-hook *post-command-hook* 'lem/tabbar::update)

;; Toggle/Disable tabbar
#+nil (lem/tabbar::toggle-tabbar)
