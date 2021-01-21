;;; -*- mode: lisp; coding: us-ascii -*-

(define-function compile-env (env -c-)
  (verbosity 1 (warn "begin compiling\n"))
  (emit-prelude -c-)
  ;; NOTE this array-do will not pick up any new definitions added to
  ;; the env after the iterations has begun (see e.g. the
  ;; COMPILE-DEFINITION of <selector>).
  (array-do var (<env>-bindings env)
    (let* ((name		(<variable>-name  var))
           (value		(<variable>-value var))
           (type-blacklist	(list <form>))
           (name-blacklist	'()))
      (unless (or (member? (type-of value) type-blacklist)
                  (member? name name-blacklist))
        (emit COMMENT (list "defn " name))
        (verbosity 1 (warn name ", "))
        (compile-definition value name -c-))))
  (verbosity 1 (warn "\n"))
  (emit-gen-buffer -c-))

;;;
;;; <selector>
;;;

(define-method compile-definition (slave-value <selector>) (name -c-)
  (let ((target-env		(slave-value *globals*))
        (methods		(eval-in-slave `(<selector>-methods ,self)))
        (target-methods		(array))
        (parameters		()))
    ;; the specialized methods
    (for (i 0 (array-length methods))
      (let ((impl-fn (array-at methods i)))
        (when impl-fn
          (let ((slave-type-id (eval-in-slave `(<type>-slave-id ,(type-object-for-id i)))))
            (emit COMMENT (list "<selector> method for "name", type id "slave-type-id" (in host: "i"), parameters: "(<expr>-parameters impl-fn)))
            ;; NOTE this takes the parameter signature of the first method
            ;; and assumes it's the same for the rest.
            (if parameters
                (assert (= (list-length parameters) (list-length (<expr>-parameters impl-fn))) "unsupported: <selector> "name" has specializations with varying number of parameters")
              (set parameters (map (lambda (el)
                                     (<variable>-name el))
                                   (<expr>-parameters impl-fn)))
              (assert (= (first parameters) 'self)))
            (let ((impl-name (string->symbol (concat-strings (symbol->string name) "." (long->string slave-type-id)))))
              (set (array-at target-methods slave-type-id)
                   ;(LABEL impl-name)
                   (environment-define target-env impl-name impl-fn))
              (compile-definition impl-fn impl-name -c-))))))
    ;; the dispatch table
    (emit COMMENT (list "<selector> dispatch table for "name))
    ;; the selector function
    (emit COMMENT (list "<selector> stub for "name))
    (let ((stub	(eval-in-target
                 `(,lambda ,parameters
                    (let ((type (type-of self)))
                      (safety 1
                        (unless (and (<= 0 type)
                                     (< type ,(array-length target-methods)))
                          ;; TODO ideally this should use the default handler provided at DEFINE-SELECTOR
                          (error "selector '",(symbol->string name)" has no method for type " (box <long> type))))
                      ;; we include the dispatch table as a literal
                      ;; array here. it will be emitted with a
                      ;; generated name into the read-only space.
                      ((oop-at ,target-methods type) ,@parameters))))))
      (compile-expr stub name () -c-))))

;;;
;;; API visible in the target
;;;
(switch-to-slave-module)

(define-form define-C-function (maru-name return-type foreign-name parameter-types)
  (let ((ff (eval-in-host `(C-function ',return-type ,(symbol->string foreign-name) ',parameter-types))))
    `(define ,maru-name ,ff)))

(define-form define-C-functions (maru-prefix . entries)
  `(let ()
     ,@(map (lambda (entry)
              (let* ((foreign-name (second entry))
                     (maru-name (concat-symbol maru-prefix foreign-name)))
                `(define-C-function ,maru-name ,@entry)))
            entries)))

(define-form define-C-variable (maru-name foreign-name type)
  (let ((fv (eval-in-host `(C-variable ,(symbol->string foreign-name) ',type))))
    `(define ,maru-name ,fv)))
