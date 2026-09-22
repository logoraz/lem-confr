;;;; dot-clasprc.lisp -> .clasprc - Clasp Initialization File

(handler-bind ((warning #'muffle-warning))
  (require :asdf)
  (require :uiop))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Enable ocicl
;;;
;; Preserving existing (uiop:xdg-data-home #P"ocicl/ocicl-registry.cfg")
;; Use setup's --force option to override.

;; Present the following code to your LISP system at startup, either
;; by adding it to your implementation's startup file
;; (~/.sbclrc, ~/.clasprc, ~/.eclrc, ~/.abclrc, ~/.clinit.cl,
;; or ~/.roswell/init.lisp)
;; or overriding it completely on the command line
;; (eg. sbcl --userinit init.lisp)

;; Note: To add other systems not registered in ocicl, simply use the
;; :tree keyword (as opposed to the default :directory) as follows. Also,
;; I wrap this initializing with `ignore-errors` so that the CL implementation
;; fails quietly...

#-ocicl
(let ((ocicl-runtime (uiop:xdg-data-home #P"ocicl/ocicl-runtime.lisp")))
  (when (probe-file ocicl-runtime)
    (load ocicl-runtime)))
(asdf:initialize-source-registry
 (list :source-registry
       ;; Needed to store non-available ocicl systems in ocicl/
       (list :directory (uiop:getcwd))
       :inherit-configuration))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Other

