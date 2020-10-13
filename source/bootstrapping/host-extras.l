;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host module while evolving from the previous stage.
;;;

;; Mark the fact that we are evolving from the previous stage.
(set evolving? true)
(eval-in-slave '(set evolving? true))

;;;
;;; Temporary definitions that are needed to enable our host to bootstrap us.
;;;

;; err, no. there are some nasty bugs in the previous stage: expand wildly expands everything,
;; and among many things it breaks the redefinition of constants which we need in the target module.
;; (define-constant false ())

;; these are new in boot.l
(define-function module-env (module)
  (<variable>-value (<module>-globals module)))

(define-function copy-module-bindings (from to filter)
  (let* ((from-env	(module-env from))
         (to-env	(module-env to))
         (from-bindings	(<env>-bindings from-env))
         (count		(array-length from-bindings)))
    (for (i 0 count)
      (let* ((var	(array-at from-bindings i))
             (name	(<variable>-name var))
             (value	(<variable>-value var)))
        ;; *globals* is special in that it should point to the module's env, therefore we skip that
        (when (or (not filter)
                  (filter name value))
          (environment-define to-env name value))))
    ()))

;; this got renamed
(define <primitive-function> <subr>)

;; new stuff
(define-form define-symbol-form (name replacement)
  `(define ,name (form () (lambda _ ',replacement))))

(define-symbol-form *module* (current-module))
