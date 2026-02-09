;;; -*- mode: lisp; coding: us-ascii -*-

;; KLUDGE due to load order headaches we set the default like this
;; instead of at the DEFINE-SELECTOR.
(set (<selector>-default compile)
     (lambda (self -c-)
       (gen LOAD (compile-object self -c-))))

;;;
;;; Emitting objects
;;;

;; FIXME? most of this shouldn't be done by hand, but automated based
;; on the type meta-data.

;; FIXME what is the difference between compiling an object and
;; emitting one? if there isn't any, then rename emit-object/foo to
;; compile-object/foo.

(define-function emit-object/C-string (self -c-)
  (let ((label (UNIQUE-LABEL "cstr")))
    (emit RODATA)
    (emit DEFLABEL label)
    (emit ASCIZ self)
    label))

(define-function compile/C-string (expr -c-)
  (assert (= (list-length expr) 2))
  (let ((label (emit-object/C-string (second expr) -c-)))
    (gen LOAD label)))

;; these will be functions instantiated later. reason: to calculate
;; some stuff and capture the result into closures. this is a poor
;; man's staged computation to speed up object emission.
(define emit-object/header)

(let* ((type		(slave-value <target-function>))
       (type-id		(slave-value (<type>-slave-id <target-function>)))
       (emit-name?	(slave-value feature/track-expr-names))
       (profiler?	(slave-value feature/profiler)))
  (define-function emit-object/<target-function> (name entry-label -c-)
    (let ((object-label	(if name
                            (LABEL (if feature/redefinable-functions-in-target
                                       (concat-string (symbol->string name) "__obj")
                                     name))
                          (UNIQUE-LABEL "oclosure")))
          (name		(when emit-name?
                          (if name
                              (compile-object (symbol->string name) -c-)
                            (compile-object () -c-))))
          (counter	(when profiler?
                          (compile-object 0 -c-))))
      (emit-object/header type type-id -c-)
      (emit DEFLABEL object-label)
      (emit CELL entry-label)
      (when name
        (emit CELL name))
      (when counter
        (emit CELL counter))
      object-label)))

(define-method compile-object <undefined> (-c-)
  (LITERAL (target-value false)))

(cond
  ((slave-value (is <immediate-type> <long>))

   (define-method compile-object <long> (-c-)
     (LITERAL (eval-in-slave `(box <long> ,self)))))

  ((slave-value (and (is <boxed-type> <long>)
                     (<boxed-type>-one-word? <long>)))
   (let ((type-id (slave-value (<type>-slave-id <long>))))

     (define-method compile-object <long> (-c-)
       (emit-object/header <long> type-id -c-)
       (let ((object-label (UNIQUE-LABEL "longo")))
         (emit DEFLABEL object-label)
         (emit CELL self)
         object-label))))

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

(define-function initialize-object-emitters ()
  ;; FIXME this would be too early to read the slave header flags at the toplevel
  (set emit-object/header
       (let ((flags		(slave-value (+ <header>-flags/used <header>-flags/opaque)))
             ;; TODO FIXME adding another level of let, or using let*
             ;; results in confused bindings and/or closure capturing.
             ;; TODO undo the inlining once eval/closures/bug/1 is fixed
             ;; TODO extract a test case into tests/evaluator-tests.l
             ;;(canary-value	(slave-value +canary-value+))
             (canary-emitter	(when (slave-value feature/object-canary)
                                  (lambda (-c-)
                                    (emit CELL (slave-value +canary-value+))))))
         (lambda (type type-id -c-)
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
           ))))
