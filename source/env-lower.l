;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/env-min.l")

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
