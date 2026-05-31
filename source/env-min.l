;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO find the set of necessary primitives and install them as <target-function>
;; and then use those primitives to implement here whatever else is needed.

;; this could be a visitor function using closures, but results in some 5-10% slowdown when used in find-local-variable
(define-form %env-do-reverse (env . body)
  `(let* ((-bindings-	(<env>-bindings ,env))
          (-index-	(array-length -bindings-))
          (__result	())
          (__vars	(<array>-elements -bindings-))) ; an early optimization that will bite us somewhere down the road...
     (while (and (not __result)
                 (<= 0 (decr -index-)))
       (let ((-variable- (oop-at __vars -index-)))
         (set __result (let () ,@body))))
     __result))

;; TODO this would reverse the order
;; (define-function copy-module-bindings (from to filter)
;;   (let* ((from-env	(module-env from))
;;          (to-env	(module-env to)))
;;     (%env-do-reverse from-env
;;       (let ((name	(<variable>-name -variable-))
;;             (value	(<variable>-value -variable-)))
;;         (when (or (not filter)
;;                   (filter name value))
;;           (environment-define to-env name value)))
;;       ())))

;; (define-function copy-module-bindings (from to filter)
;;   (let* ((from-env	(module-env from))
;;          (to-env	(module-env to))
;;          (from-bindings	(<env>-bindings from-env))
;;          (count		(array-length from-bindings)))
;;     (for (i 0 count)
;;       (let* ((var	(array-at from-bindings i))
;;              (name	(<variable>-name var))
;;              (value	(<variable>-value var)))
;;         (when (or (not filter)
;;                   (filter name value))
;;           (environment-define to-env name value))))
;;     ()))

(define-function find-local-variable (env name)
  (safety 2 (assert (is <env> env) "find-local-variable: env is not an <env>: "env))
  (safety 2 (assert (symbol? name) "find-local-variable: name is not a <symbol>: "name))
  (%env-do-reverse env
    (and (= name (<variable>-name -variable-))
         -variable-)))

(define-function variable-value (env name)
  (safety 3 (assert (= 0 (unbox <long> (<env>-level env)))) "variable-value called with non-toplevel env "env)
  (aif (defined? name env)
      (<variable>-value it)
    ;;(error "variable-value: undefined variable '"name"' in module "module)
    ()))

(define-function set-variable-value (env name value)
  (safety 3 (assert (= 0 (unbox <long> (<env>-level env)))) "set-variable-value called with non-toplevel env "env)
  ;;(safety 3 (or (symbol? name) (fatal "set-variable-value called with a non-symbol name")))
  (debug (platform/diag-print "set-variable-value for " (string (symbol->string name)) "\n"))
  (aif (defined? name env)
      (set (<variable>-value it) value)
    (environment-define env name value)
    value))
