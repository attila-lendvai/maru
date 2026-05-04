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
    (emit-comment 3 "emitting object header for type-id: "type-id)

    (with-current-segment 'data
      (.align +word-size-in-bytes+)

      ;; NEXT and CHUNK-SIZE should only ever be read by the GC,
      ;; but this here is the emission of read-only literals. the
      ;; GC should never walk these objects, therefore we can
      ;; skip emitting the first two words of the header.

      ;; next         ; not emitted
      ;; chunk size   ; not emitted
      (emit CELL flags)
      (emit CELL type-id)
      (when canary-emitter
        (canary-emitter -c-)))
    ;; the object pointer points here
    ))

(let* ((type		(slave-value <target-function>))
       (type-id		(slave-value (<type>-slave-id <target-function>)))
       (emit-name?	(feature track-expr-names))
       (profiler?	(feature profiler)))
  (define-function emit-object/<target-function> (name entry-label -c-)
    ;; TODO into data or ro-data? ideally, all literals should go into
    ;; ro-data, but then e.g. the profiler counter will be read-only.
    (let ((name-op	(when emit-name?
                          (compile-object (if name (symbol->string name) ()) -c-)))
          (counter	(when profiler?
                          (compile-object 0 -c-))))
      (emit-object/header type type-id -c-)
      (with-new-label 'data
        (when name
          (emit-symtab-entry/variable name +.data-section-index+
                                      (current-laddress)
                                      +word-size-in-bytes+)
          ;; we define the object's address into the assembler env
          ;; (instead of the entry-point to the actual machine
          ;; instructions). this is needed so that when a function is
          ;; used as a variable, then the full object is loaded, not
          ;; the address of the entry point.
          (label! name))
        (emit CELL (GLOBAL-ADDR entry-label))
        (when name-op
          (emit CELL name-op))
        (when counter
          (emit CELL counter))))))

(cond
  ((slave-value (is <immediate-type> <long>))

   (define-method compile-object <long> (-c-)
     (LI64 (eval-in-slave `(box <long> ,self)))))

  ((slave-value (and (is <boxed-type> <long>)
                     (<boxed-type>-one-word? <long>)))
   (if-at-expand (feature emit-with-object-headers)
       (let ((type-id (slave-value (<type>-slave-id <long>))))

         (define-method compile-object <long> (-c-)
           (emit-object/header <long> type-id -c-)
           (GLOBAL-ADDR
            (with-new-label 'data
              (emit CELL self)))))
     (error "Cannot emit boxed <long> when not emitting full objects")))

  (else (error "emit-object: unexpected slave representation for <long>")))

(let ((type-id (slave-value (<type>-slave-id <string>)))
      (counter 0))
  (define-method compile-object <string> (-c-)
    (emit-comment 3 "emitting string object: "self)
    ;; NOTE self here is a host string object, i.e. it's not according to the slave layout
    (let ((elements	(emit-object/C-string self -c-))
          (size		(compile-object (string-length self) -c-)))
      (emit-object/header <string> type-id -c-)
      (GLOBAL-ADDR
       (with-new-label 'data
         (incr counter)
         (emit-symtab-entry/variable (concat-string "str" (integer->string counter))
                                     +.data-section-index+
                                     (current-laddress)
                                     +word-size-in-bytes+)
         (emit CELL size)
         (emit CELL elements))))))

;;;
;;; Function calls
;;;

(define-function compiled-expr-wrapper (name entry-point -c-)
  (emit-object/<target-function> name entry-point -c-))
