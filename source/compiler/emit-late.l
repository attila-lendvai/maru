;;; -*- mode: lisp; coding: us-ascii -*-

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
        (dispatch-table-name	(concat-symbols name '.method-table))
        (parameters		())
        (index-min		())
        (index-max		0))
    ;; build a trimmed methods array with the slave type id's as indexes
    (for (i 0 (array-length methods))
      (let ((impl-fn (array-at methods i)))
        (when impl-fn
          (let ((slave-type-id (eval-in-slave `(<type>-slave-id ,(type-object-for-id i)))))
            (emit-comment 2 "<selector> method for "name", type id "slave-type-id" (in host: "i"), parameters: "(<expr>-parameters impl-fn))
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
                      ((oop-at (address-of ,dispatch-table-name) (- type ,index-min)) ,@parameters))))))
      (compile-definition stub name -c-))))
