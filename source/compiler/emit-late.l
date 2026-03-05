;;; -*- mode: lisp; coding: us-ascii -*-

(define-function features->print-forms (names)
  (let ((elements ())
        (first-time true))
    (map (lambda (name)
           (if first-time
               (set first-time false)
             (push elements ", "))
           (push elements (symbol->string name))
           (push elements "=")
           (push elements `(feature ,name)))
         names)
    (list-reverse! elements)))

(define-form comment-features ()
  `(emit-comment 0 "features: "
                 ,@(features->print-forms
                    '(emit-with-object-headers
                      redefinable-functions-in-target
                      strict-semantics-for-compiled-set
                      profiler
                      track-expr-names
                      object-canary
                      debug-info))))

(define-function compile-env (env -c-)
  (verbosity 1
    (warn "begin compiling env with "(array-length (<env>-bindings env))" definitions\n\n")
    (map (lambda (sym)
           (warn (symbol->string sym)"	"(eval-in-slave sym)"\n"))
         '(+operating-system+ +architecture+ +little-endian?+
           +word-size-in-bits+
           ;;oop/alignment-in-bytes oop/align-padding
           ;;oop/payload-mask oop/tag-mask
           )))
  (comment-features)
  (emit-prelude -c-)
  ;; NOTE this array-do will not pick up any new definitions added to
  ;; the env after the iterations has begun (see e.g. the
  ;; COMPILE-DEFINITION of <selector>).
  (array-do var (<env>-bindings env)
    (let* ((name		(<variable>-name  var))
           (value		(<variable>-value var))
           (type-blacklist	(list <form> <fixed>))
           (name-blacklist	'()))
      (unless (or (member? (type-of value) type-blacklist)
                  (member? name name-blacklist))
        (emit-comment 1 "defn "name)
        (verbosity 1 (warn name ", "))
        (compile-definition value name -c-))))
  (verbosity 1 (warn "\n"))
  (emit-gen-buffer -c-))

;;;
;;; <selector>
;;;
;; TODO ideally the method vector of the selector should be
;; addressed/filled according to the slave type id's. when that is
;; achieved, then we can simply COMPILE-DEFINITION the method array,
;; without the translation.
;;
;; TODO this whole thing should be merged with the emit-object stuff,
;; or rather, with whatever simplified will replace the current
;; emit-object machinery.
(define-method compile-definition (slave-value <selector>) (name -c-)
  (let ((target-env		(slave-value *globals*))
        (methods		(eval-in-slave `(<selector>-methods ,self)))
        (target-methods		(array))
        (dispatch-table-name	(concat-symbols name '-table))
        (parameters		())
        (index-min		())
        (index-max		0))
    ;; build a trimmed methods array with the slave type id's as indexes
    (for (i 0 (array-length methods))
      (let ((impl-fn (array-at methods i)))
        (when impl-fn
          (let ((slave-type-id (eval-in-slave `(<type>-slave-id ,(type-object-for-id i)))))
            (emit-comment 1 "<selector> method for "name", type id "slave-type-id" (in host: "i"), parameters: "(<expr>-parameters impl-fn))
            (or index-min (set index-min slave-type-id))
            (set index-max slave-type-id)
            ;; NOTE this takes the parameter signature of the first method
            ;; and assumes it's the same for the rest.
            (if parameters
                (assert (= (list-length parameters) (list-length (<expr>-parameters impl-fn))) "unsupported: <selector> "name" has specializations with varying number of parameters")
              (set parameters (map (lambda (el)
                                     (<variable>-name el))
                                   (<expr>-parameters impl-fn)))
              (assert (= (first parameters) 'self)))
            (set (array-at target-methods (- slave-type-id index-min)) impl-fn)))))
    ;; define and emit the dispatch table
    (emit-comment 1 "<selector> dispatch table for '"name"', from "index-min", to "index-max)
    (environment-define target-env dispatch-table-name target-methods)
    (compile-definition target-methods dispatch-table-name -c-)
    ;; the selector function
    (emit-comment 1 "<selector> stub for "name)
    (let ((stub	(eval-in-target
                 `(,lambda ,parameters
                    (let ((type (type-of self)))
                      (safety 1
                        (unless (and (<= ,index-min type)
                                     (<= type ,index-max))
                          ;; TODO ideally this should use the default handler provided at DEFINE-SELECTOR
                          (error "selector '",(symbol->string name)"' has no method for type " (box <long> type))))
                      ;; TODO eliminate the extra indirection from the global var to the dispatch array
                      ((oop-at ,dispatch-table-name (- type ,index-min)) ,@parameters))))))
      (compile-definition stub name -c-))))
