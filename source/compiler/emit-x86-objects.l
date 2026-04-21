;;; -*- mode: lisp; coding: us-ascii -*-

;;; This file redefines a few functions in the compiler so that they
;;; emit full objects from the perspective of the GC.

;;; FIXME? most of this shouldn't be done by hand, but automated based
;;; on the type meta-data.

(let ((flags		(slave-value (+ <header>-flags/used <header>-flags/opaque)))
      ;; TODO FIXME adding another level of let, or simply replacing
      ;; let with let* results in confused bindings and/or closure
      ;; capturing.
      ;; TODO undo the inlining once this is fixed
      ;; is fixed (canary-value (slave-value +canary-value+))
      (canary-emitter	(when (feature object-canary)
                          (lambda (-c-)
                            (emit CELL (slave-value +canary-value+))))))

  (define-function emit-object/header (type type-id -c-)
    (emit-comment 1 "object header")
    ;; NOTE cannot use RODATA because the header and the object
    ;; payload must be consequtive, but the payload values must
    ;; be relocatable.
    (emit DATA)
    (emit ALIGN +word-size-in-bytes+)

    ;; NEXT and CHUNK-SIZE should only ever be read by the GC,
    ;; but this here is the emission of read-only literals. the
    ;; GC should never walk these objects, therefore we can
    ;; skip emitting the first two words of the header.

    ;; next         ; not emitted
    ;; chunk size   ; not emitted
    (emit CELL flags)
    (emit-comment 2 "type: "type)
    (emit CELL type-id)
    (when canary-emitter
      (canary-emitter -c-))
    ;; the object pointer points here
    ))

(let* ((type		(slave-value <target-function>))
       (type-id		(slave-value (<type>-slave-id <target-function>)))
       (emit-name?	(feature track-expr-names))
       (profiler?	(feature profiler)))
  (define-function emit-object/<target-function> (name entry-label -c-)
    (let ((object-label	(if name
                            (LABEL (if (feature redefinable-functions-in-target)
                                       (concat-string (symbol->string name) "__obj")
                                     name))
                          (UNIQUE-LABEL "oclosure")))
          (name		(when emit-name?
                          (if name
                              (compile-object (symbol->string name) -c-)
                            (compile-object () -c-))))
          (counter		(when profiler?
                                  (compile-object 0 -c-))))
      (emit-object/header type type-id -c-)
      (emit DEFLABEL object-label)
      (emit CELL entry-label)
      (when name
        (emit CELL name))
      (when counter
        (emit CELL counter))
      object-label)))

(cond
  ((slave-value (is <immediate-type> <long>))

   (define-method compile-object <long> (-c-)
     (LITERAL (eval-in-slave `(box <long> ,self)))))

  ((slave-value (and (is <boxed-type> <long>)
                     (<boxed-type>-one-word? <long>)))
   (if-at-expand (feature emit-with-object-headers)
       (let ((type-id (slave-value (<type>-slave-id <long>))))

         (define-method compile-object <long> (-c-)
           (emit-object/header <long> type-id -c-)
           (let ((object-label (UNIQUE-LABEL "longo")))
             (emit DEFLABEL object-label)
             (emit CELL self)
             object-label)))
     (error "Cannot emit boxed <long> when not emitting full objects")))

  (else (error "emit-object: unexpected slave representation for <long>")))

(let ((type-id (slave-value (<type>-slave-id <string>))))
  (define-method compile-object <string> (-c-)
    ;; NOTE self here is a host string object, i.e. it's not according to the slave layout
    (let ((elements	(emit-object/C-string self -c-))
          (size		(compile-object (string-length self) -c-))
          (object-label	(UNIQUE-LABEL "ostr")))
      (emit-object/header <string> type-id -c-)
      (emit DEFLABEL object-label)
      (emit CELL size)
      (emit CELL elements)
      object-label)))

;;;
;;; Function calls
;;;

;; TODO should this also go through the COMPILE-OBJECT selector? but
;; what about the NAME arg then?
(define-function closure-code-label (name)
  ;; KLUDGE object "names" (i.e. addresses) should be tied together
  ;; explicitly, not through giving them the "right" name
  (LABEL (concat-string (symbol->string name) "__code")))

(define-function compile-expr (self name -c-)
  (emit-comment 1 "compiling fn "(or name "/unnamed/")", "self)
  (let ((entry-point (if name
                         (closure-code-label name)
                       (UNIQUE-LABEL "code"))))
    (emit-expr-code self entry-point -c-)
    ;; we emit a full expr object to keep the rest of the code more
    ;; uniform. FIXME: write a better reasoning why this is done this
    ;; way. it should have to do something with funcall'ing random
    ;; closures, of which compiled functions are just one kind.
    (emit-object/<target-function> name entry-point -c-)))
