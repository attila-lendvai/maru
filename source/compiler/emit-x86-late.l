;;; -*- mode: lisp; coding: us-ascii -*-

(define-method compile <long> (-c-)
  ;; FIXME: We can't call COMPILE-OBJECT here, because that would box
  ;; the value. But then why the lack of symmetry with <string> and
  ;; other literals in the code (they are emitted as full heap objects)?
  (gen LOAD (LITERAL self)))

;;;
;;; COMPILE-DEFINITION
;;;
;; TODO a lot of this is the same in the 32 bits
(define-method compile-definition <type>		(name -c-)	(emit COMMENT (list "type "name))) ; we don't need (target-value <type>) here because <type> is "reused" by the slave from the host
(define-method compile-definition <undefined>		(name -c-)	(compile-definition (target-value false) name -c-))
(define-method compile-definition <C-function>		(name -c-)	(emit COMMENT (list "C function "name))) ; it will be handled at the call site
(define-method compile-definition <C-variable>		(name -c-)	(emit COMMENT (list "C variable "name))) ; it will be handled at the site of reference

(define-method compile-definition <long> (name -c-)
  (emit DATA)
  (emit DEFLABEL (LABEL name))
  (emit CELL self))

;; kinda KLUDGE
;; this is used when emitting the literal dispatch tables of <selectors>
(define-method compile-definition <array> (name -c-)
  (let ((compiled (compile-array self -c-))
        (array-label (UNIQUE-LABEL "arr")))
    (emit DATA)
    (emit DEFLABEL array-label)
    (array-do el compiled
      (emit CELL el))
    ;; TODO comment on why an extra indirection is present here
    ;; (probably to keep the harmony with other definitions).
    (emit DEFLABEL (LABEL name))
    (emit CELL array-label)))

(define-method compile-definition <expr> (name -c-)
  (assert name)
  (let ((object-label (compile-expr self name -c-))
        (code-label   (closure-code-label name)))
    (if (member? name '(main _start)) ; KLUDGE special case the entry points
        (let ((external-label (EXTERNAL-LABEL name)))
          (emit ALIAS external-label code-label)
          (emit EXPORT external-label))
      (emit EXPORT code-label))
    (emit TYPE code-label "@function")
    (when feature/redefinable-functions-in-target
      (let ((label (LABEL name)))
        (emit DATA)
        (emit DEFLABEL label)
        (emit CELL object-label)))))

(require "source/compiler/emit-late.l")
