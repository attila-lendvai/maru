;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; Emitting objects
;;;

;; KLUDGE this shouldn't be done by hand, but automated based on the type meta-data

;; these will be functions instantiated later. reason: to calculate
;; some stuff and capture the result into closures. this is a poor
;; man's staged computation to speed up object emission.
(define emit-object/header)
(define emit-object/<string>)
(define emit-object/<long>)
(define emit-object/<target-function>)

(define-function initialize-object-emitters ()
  (set emit-object/header
       (let ((flags		(slave-value (+ <header>-flags/used <header>-flags/opaque)))
             ;; TODO FIXME adding another level of let, or using let*
             ;; results in confused bindings and/or closure capturing.
             ;; TODO undo the inlining once eval/closures/bug/1 is fixed
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

           ; next         ; not emitted
           ; chunk size   ; not emitted
           (emit CELL flags)
           (emit-comment 2 "type: "type)
           (emit CELL type-id)
           (when canary-emitter
             (canary-emitter -c-))
           ; the object pointer points here
           )))

  (set emit-object/<long>
       ;; TODO it should be something like: (target-value <string>). see others, too.
       (cond
         ((slave-value (is <immediate-type> <long>))
          (lambda (self -c-)
            ;; instead of a label (a pointer) we return with an immediate tagged mword
            (eval-in-slave `(box <long> ,self))))
         ((slave-value (and (is <boxed-type> <long>)
                            (<boxed-type>-one-word? <long>)))
          (let ((type-id (slave-value (<type>-slave-id <long>))))
            (lambda (self -c-)
              (emit-object/header <long> type-id -c-)
              (let ((object-label (UNIQUE-LABEL "olong")))
                (emit DEFLABEL object-label)
                (emit CELL self)
                object-label))))
         (else
          (error "emit-object/<long>: unexpected slave representation for <long>"))))

  (set emit-object/<string>
       (let ((type-id (slave-value (<type>-slave-id <string>))))
         (lambda (self -c-)
           (safety 1 (assert (is <string> self)))
           ;; NOTE self here is a host string object, i.e. it's not according to the slave layout
           (let ((elements	(emit-object/C-string self -c-))
                 (size		(emit-object/<long> (string-length self) -c-))
                 (object-label	(UNIQUE-LABEL "ostr")))
             (emit-object/header <string> type-id -c-)
             (emit DEFLABEL object-label)
             (emit CELL size)
             (emit CELL elements)
             object-label))))

  (set emit-object/<target-function>
       (let* ((type		(slave-value <target-function>))
              (type-id		(slave-value (<type>-slave-id <target-function>)))
              (null-value	(slave-value (<immediate-type>-tag-value <undefined>)))
              (name-factory	(when (slave-value feature/track-expr-names)
                                  (lambda (name -c-)
                                    (if name
                                        (emit-object/<string> (symbol->string name) -c-)
                                      null-value))))
              (profiler?	(slave-value feature/profiler)))
         (lambda (name entry-label -c-)
           (let ((object-label	(if name
                                    (LABEL (if feature/redefinable-functions-in-target
                                               (concat-string (symbol->string name) "__obj")
                                             name))
                                  (UNIQUE-LABEL "oclosure")))
                 (name		(when name-factory
                                  ;; NOTE this must happen first due
                                  ;; to the order of emission.
                                  (name-factory name -c-)))
                 (counter	(when profiler?
                                  (emit-object/<long> 0 -c-))))
             (emit-object/header type type-id -c-)
             (emit DEFLABEL object-label)
             (emit CELL entry-label)
             (when name
               (emit CELL name))
             (when counter
               (emit CELL counter))
             object-label)))))
