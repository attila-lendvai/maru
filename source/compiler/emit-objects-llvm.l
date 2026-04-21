;;; -*- mode: lisp; coding: us-ascii -*-

;;; Capturing values into closures is a poor man's staged computation
;;; to speed up emission.

;;; FIXME? most of this shouldn't be done by hand, but automated based
;;; on the type meta-data.

;;;
;;; Emitting objects
;;;
(let ((flags		(slave-value (+ <header>-flags/used <header>-flags/opaque)))
      ;; TODO FIXME if this let is a let*, and the canary-value
      ;; binding is also uncommented, then it results in
      ;; confused bindings and/or closure capturing that
      ;; crashes while compiling (ERROR: cannot apply: 13 of
      ;; type: 7). i couldn't yet extract a reproducer.

      ;;(canary-value (slave-value +canary-value+))
      (canary-emitter	(if (feature object-canary)
                            (lambda () (print ", %word "(slave-value +canary-value+)))
                          (lambda ()))))
  (define-function emit-object/header (type-id)
    (print "%\"<header>\" { %word "flags", %word "type-id)
    (canary-emitter)
    (print "}")))

(let ((type-id		(slave-value (<type>-slave-id <target-function>)))
      (name-factory	(when (feature track-expr-names)
                          (lambda (name -c-)
                            (if name
                                (compile-object (symbol->string name) -c-)
                              "null"))))
      (profiler?		(feature profiler)))
  (define-function emit-object/<target-function> (expr name entry-label -c-)
    (let ((object-label	(if name
                            (closure-object-label name)
                          (GLOBAL (unique-name "oclosure"))))
          (name-object	(when name-factory (name-factory name -c-)))
          (counter	(when profiler? (compile-object 0 -c-))))
      ;; TODO? this here is an (emit DEFINE (CONSTANT ...) ...) inlined
      (print object-label" = private unnamed_addr constant %\"<target-function-h>\" { ")
      (emit-object/header type-id)
      (print ", %\"<target-function>\" { %oop bitcast (")
      (emit-llvm-fn-type-for-expr expr)
      (print "* "entry-label" to %oop)")
      (when name-object
        (print ", %\"<string-h>\"* "name-object))
      (when counter
        (print ", %oop ")
        (emit/header->payload/in-constants name-object))
      (print " }}\n")
      (CONSTANT object-label expr))))

(cond
  ((slave-value (is <immediate-type> <long>))

   (define-method compile-object <long> (-c-)
     (LITERAL (eval-in-slave `(box <long> ,self)))))

  ((slave-value (and (is <boxed-type> <long>)
                     (<boxed-type>-one-word? <long>)))
   (let ((type-id (slave-value (<type>-slave-id <long>))))

     (if-at-expand (feature emit-with-object-headers)
         (define-method compile-object <long> (-c-)
           (let ((object-label	(GLOBAL (unique-name "olong"))))
             ;; TODO? this here is an (emit DEFINE (CONSTANT ...) ...) inlined
             (print object-label" = private unnamed_addr constant %\"<long-h>\" { ")
             (emit-object/header type-id)
             (print ", %\"<long>\" { %word "self" }}\n")
             object-label))
       (error "Cannot emit boxed <long> when not emitting full objects"))))

  (else (error "compile-object: unexpected slave representation for <long>")))

(let ((type-id (slave-value (<type>-slave-id <string>)))
      (llvm-type-for-<long> (if (slave-value (is <immediate-type> <long>))
                                "%word" "%oop")))

  (define-method compile-object <string> (-c-)
    ;; NOTE self here is a host string object, i.e. it's not according to the slave layout
    (let ((elements	(emit-object/C-string self -c-))
          (object-label	(GLOBAL (unique-name "ostr")))
          (size		(compile-object (string-length self) -c-)))
      ;; TODO? this here is an (emit DEFINE (CONSTANT ...) ...) inlined
      (print object-label" = private unnamed_addr constant %\"<string-h>\" { ")
      (emit-object/header type-id)
      ;; FIXME this assumes that <long> is a tagged immediate
      (print ", %\"<string>\" { "llvm-type-for-<long>" "size)
      (print ", ptr bitcast (["(+ 1 (string-length self))" x i8]* "
             elements" to ptr) }}\n")
      object-label)))

;;;
;;; Function calls
;;;
;;; They depend on (feature emit-with-object-headers), hence they are
;;; here.

;; TODO should this also go through the COMPILE-OBJECT selector? but
;; what about the NAME arg then?
(define-function closure-code-label (name)
  ;; KLUDGE object "names" (i.e. addresses) should be tied together
  ;; explicitly, not through giving them the "right" name
  (GLOBAL (concat-string (symbol->string name) ".code")))

(define-function compile-expr (self name -c-)
  (emit-comment 1 "compiling fn "name", "self)
  (let ((entry-point-label (if name
                               (closure-code-label name)
                             (GLOBAL (unique-name "fn")))))
    (emit-expr-code self entry-point-label -c-)
    (emit-object/<target-function> self name entry-point-label -c-)))
