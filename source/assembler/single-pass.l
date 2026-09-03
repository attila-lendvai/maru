;;; -*- mode: lisp; coding: us-ascii -*-

;;; This is an assembler that can be used programmatically, and it
;;; runs in a single pass. Because of that forward labels are a bit
;;; more complex to use.

(require "source/files.l")
(require "source/env-min.l")

(define-record <segment> ()
  (buffer     ; the output, a binary buffer
   laddress   ; logical address
   paddress   ; physical address; i.e. current offset in the buffer
   %name      ; only for debugging
   ))

(define-print-method <segment> (print-all -stream- "<segment "self.%name">"))

(define-record <assembler> ()
  (env        ; a lexical env where the asm instructions are evaluated
   current-segment ; the <segment> we are emitting into
   relocations     ; list of (hole-segment hole-paddress target size offset type)
   ))

(define *assembler*) ; TODO turn this into something else than a global variable

(define-function create-segment (name)
  (let ((segment
          (make <segment>
            (buffer	(memory-block 4096))
            (%name	name)
            ;; TODO for a working address-of upper function we either need
            ;; full-cell <long>, or more generally use <lower-cell> and
            ;; introduce arithmetic for that in the interpreter. for
            ;; now we just settle for generating position independent
            ;; code for any JIT-like scenario, and when we output ELF
            ;; files, we can just set the base explicitly.
            ;;
            ;; to make non-PIC code call'able right in the emit buffer
            ;; (laddress	(address-of (<buffer>-elements buffer)))
            (laddress	0xdeadbeef)
            (paddress	0)
            ))
        (env (<assembler>-env *assembler*)))
    (when (defined? name env)
      (error "create-segment: the segment is already defined: "name" with value: "(variable-value env name)))
    (environment-define env name segment)
    ;; the first segment created becomes the current-segment
    (unless (<assembler>-current-segment *assembler*)
      (set (<assembler>-current-segment *assembler*) segment))
    segment))

(define-form with-assembling (args . body)
  (let ((segment-names (pop args)))
    `(let ((__asm-backup__ *assembler*))
      (set *assembler*
           (make <assembler>
             (env		(environment))
             ))
      ,@(map (lambda (el)
               (let ((name (first (ensure-list el)))
                     (base (second (ensure-list el))))
                 (if base
                     `(set (<segment>-laddress (create-segment ',name))
                           ,base)
                   `(create-segment ',name))))
             segment-names)
      ,@body
       (set *assembler* __asm-backup__)
       ())))

(define-function current-segment ()
  (let ((segment (<assembler>-current-segment *assembler*)))
    (assert (is <segment> segment))
    segment))

(define-form with-current-segment (new-segment . body)
  `(let ((__previous-segment__ (current-segment)))
     (.segment ,new-segment)
     (let ((__result__ (begin ,@body)))
       (.segment __previous-segment__)
       __result__)))

(define-form with-new-label (segment . body)
  (let ((result `(let ((-label- (label!)))
                   ,@body
                   -label-)))
    (if segment
        `(with-current-segment ,segment
           ,result)
      result)))

(define-function get-segment (desig)
  (typecase desig
    (<symbol> (let ((segment (variable-value (<assembler>-env *assembler*) desig)))
                (assert (is <segment> segment))
                segment))
    (<segment> desig)
    (else (error "get-segment: not a valid segment designator: "desig))))

;; the segment's base vaddr; the laddress slot is a moving cursor that
;; advances with emission, so it must be rebased by the paddress
(define-function segment-base (desig)
  (let ((segment (get-segment desig)))
    (- (<segment>-laddress segment)
       (<segment>-paddress segment))))

(define-function segment-length (desig)
  (memory-block/length (<segment>-buffer (get-segment desig))))

(define-function .segment (desig)
  (typecase desig
    (<segment> (set (<assembler>-current-segment *assembler*) desig))
    (<symbol>  (.segment (get-segment desig)))
    (else (error ".segment: not a valid segment designator: "desig))))

(define-function write-segment-to-stream (desig stream)
  ;;(print-all *debug-output* "writing segment: "desig", size: "(segment-length desig)"\n")
  (lower/$put-all stream (<segment>-buffer (get-segment desig))))

;; used by the tests
(define-function save-current-segment-to-file (filename)
  (with-open-stream (stream filename "w")
    (write-segment-to-stream (current-segment) stream)))

(define-function segment->function (segment)
  (memory-block->lower/function (<segment>-buffer segment)))

(define-function assembler->function (a)
  (segment->function (<assembler>-current-segment a)))

;;;
;;; Labels
;;;
;;; Labels are objects that can be used in two ways:
;;;
;;;   1) anonymously as objects in local variables while generating
;;;      code
;;;
;;;   2) or they can be "entire-program" labels referenced as
;;;      symbols. they get defined into an environment that the
;;;      assembler holds.
;;;
;;; The API should accept both interchangably and do the necessary
;;; lookup/define as needed.
;;;
;;; Glossary:
;;;  - forward label: a label whose paddress/laddress we don't know yet.
;;;  - p prefix: physical address, i.e. the buffer positiion of the assembler.
;;;  - l prefix: logical address, i.e. where the code will run

(define-function current-paddress ()
  (<segment>-paddress (current-segment)))

(define-function set-current-paddress (value)
  (set (<segment>-paddress (current-segment)) value))

(define-function current-laddress ()
  (<segment>-laddress (current-segment)))

(define-function set-current-laddress (value)
  (set (<segment>-laddress (current-segment)) value))

(define-form with-segment-position-backup (segment . body)
  `(let* ((__segment		,segment)
          (__saved-paddress	(<segment>-paddress __segment))
          (__saved-laddress	(<segment>-laddress __segment))
          (__result (begin ,@body)))
     (set (<segment>-paddress __segment) __saved-paddress)
     (set (<segment>-laddress __segment) __saved-laddress)
     __result))

;; A relocation target that the static linker resolves by name (e.g.
;; an imported C symbol). Unlike a <label>, it never gets defined.
(define-record <reloc-symbol> ()
  (name))

(define-function reloc-symbol (name)
  (make <reloc-symbol> (name name)))

;; Records a relocation against the fixup hole at the current
;; position. TARGET is either a <label> (resolved to a section symbol
;; + offset at serialization time) or a <reloc-symbol>.
(define-function %record-relocation (target type size offset)
  (push (<assembler>-relocations *assembler*)
        (list (current-segment)
              (current-paddress)
              target
              size
              offset
              type)))

(define-record <label> ()
  (segment
   %name ; for debugging
   paddress
   laddress
   ;; primed-emitter is needed so that we can write something like
   ;; this: (MOVQir32 (label 'msg-end (- self (laddress 'msg))) RDX)
   ;; i.e. a LABEL that sets an emitter that encodes the requested
   ;; calculation, and the instruction emitter eventually picks up the
   ;; label emitter and calls the future to calculate the offset.
   primed-emitter
   emitters))

(define-function %find-label (desig)
  (typecase desig
    (<label>	desig)
    (<symbol>	(maybe-variable-value (<assembler>-env *assembler*) desig))
    (else (error "%find-label: not a label designator: "desig", of type: "(type-of desig)))))

(define-function %ensure-label (desig)
  ;; create a label if needed, with its addresses unset (i.e. it can
  ;; be a future label)
  (let ((label (%find-label desig)))
    (unless label
      (set label (make <label>
                   (segment	(current-segment))
                   (%name	desig)))
      (when (is <symbol> desig)
        (environment-define (<assembler>-env *assembler*) desig label)))
    label))

(define-print-method <label> (print-all -stream- "<label "self.%name", "self.segment">"))

(define-function resolved-label? (label)
  (and (is <long> (<label>-paddress label))
       (is <long> (<label>-laddress label))))

(define-function %get-label (desig)
  (typecase desig
    (<symbol>	(let ((label (variable-value (<assembler>-env *assembler*) desig)))
                  (assert (is <label> label))
                  label))
    (<label>	desig)
    (else (error "%get-label: not a label designator: "desig", of type: "(type-of desig)))))

(define-function %get-resolved-label (desig)
  (let ((label (typecase desig
                 (<symbol>	(%get-label desig))
                 (<label>	desig)
                 (else (error "%get-resolved-label: not a label designator: "desig", of type: "(type-of desig))))))
    (assert (resolved-label? label))
    label))

(define-function label! args
  (let ((desig		(pop args))
        (laddress	(or (pop args) (current-laddress)))
        (paddress	(or (pop args) (current-paddress))))
    (if desig
        (let ((label (%ensure-label desig)))
          ;; (print-all *debug-output* "label! is defining label "label", at laddress 0x"
          ;;            (integer->string laddress 16)
          ;;            ", paddress: 0x" (integer->string paddress 16)
          ;;            ", desig: " desig
          ;;            "\n")
          (when (or (<label>-paddress label)
                    (<label>-laddress label))
            (error "trying to define an already defined label: "desig))
          (set (<label>-segment label)	(current-segment))
          (set (<label>-paddress label)	paddress)
          (set (<label>-laddress label)	laddress)
          (list-do emitter (<label>-emitters label)
            ;;(print-all *debug-output* "label! is calling an emitter\n")
            (emitter 'state/set paddress laddress))
          label)
      (make <label>
        (segment	(current-segment))
        (paddress	paddress)
        (laddress	laddress)))))

(define-function paddress (name) (<label>-paddress (%get-resolved-label name)))
(define-function laddress (name) (<label>-laddress (%get-resolved-label name)))

(define-function %label args
  (if args
      (let ((desig (pop args)))
        (assert (not args))
        (%ensure-label desig))
    (make <label>
      (segment (current-segment)))))

(define-form label args
  (if (second args)
      (let ((desig (pop args))
            (value-form (pop args)))
        (assert (not args))
        `(%prime-label (%ensure-label ,desig) (lambda (pself self) ,value-form)))
    `(%label ,@args)))

(define-function %prime-label (desig value-future)
  (let ((label		(%ensure-label desig))
        (env		(<assembler>-env *assembler*))
        (hole-paddress	())
        (hole-segment	())
        (writer		())
        (offset		false)
        (size		false)
        (reloc-type	false))
    (let ((emitter
            (lambda (state . args)
              (case state
                (state/emit
                 (set hole-paddress (current-paddress))
                 (set hole-segment (current-segment))
                 ;; (print-all *debug-output* "state/emit for label "label
                 ;;              ", hole-paddress: 0x" (integer->string hole-paddress 16)
                 ;;              ", hole-segment: "  hole-segment
                 ;;              ", (current-segment): " (current-segment)
                 ;;              "\n")
                 (set writer (pop args))
                 (set offset (pop args))
                 (set size (pop args))
                 (set reloc-type (pop args))
                 ;; reloc-type is absent for fixups that have no
                 ;; relocation mapping yet (e.g. absolute imm fields)
                 (when reloc-type
                   (%record-relocation label (first reloc-type) size offset)))
                (state/set
                 (let* ((paddress (pop args))
                        (laddress (pop args)))
                    ;; the writers write into (current-segment), so we must set it
                    (with-current-segment hole-segment
                      (with-segment-position-backup hole-segment
                        (set (<segment>-paddress hole-segment) hole-paddress)
                        ;; it's a forward label, so the form that calculates
                        ;; the final value must be delayed into a future (a
                        ;; closure). but now is the time to force it.
                        (let ((final-laddress (value-future paddress laddress)))
                          (when offset
                            (incr final-laddress offset))
                          ;; (print-all *debug-output* "state/set of an emitter, laddress 0x"
                          ;;            (integer->string laddress 16)
                          ;;            ", paddress: 0x" (integer->string paddress 16)
                          ;;            ", hole-paddress: 0x" (integer->string hole-paddress 16)
                          ;;            ", hole-segment: "  hole-segment
                          ;;            ", final-laddress: 0x"  (integer->string final-laddress 16)
                          ;;            ", writer: " writer
                          ;;            "\n")
                          (writer final-laddress)))))
                  ())
                 (else (error "unexpected state: "state))))))
      (assert (not (<label>-primed-emitter label)))
      (set (<label>-primed-emitter label) emitter))
    label))

;;;
;;; Hooks for interfacing with the instruction emitters
;;;

(define-function emit-label (label writer size . rest)
  ;; this is only called from the writers of the instructions, so the
  ;; current segment is the right segment. REST carries an optional
  ;; OFFSET (a <long>; the positional adjustment applied to the
  ;; label's address), followed by the optional RELOC-TYPE (a
  ;; one-element list; passed by callers whose fixups can be turned
  ;; into relocations, see %record-relocation; when emitting a
  ;; relocatable object it selects the relocation type).
  (let ((offset (and (pair? rest)
                     (is <long> (first rest))
                     (pop rest)))
        (reloc-type rest))
    (if (resolved-label? label)
        (begin
         (assert (not (<label>-primed-emitter label)))
         ;; if there's no primed emitter, then there's no calculation
         ;; specified, so we just write out the laddress without
         ;; instantiating closures and doing some extra dance that is
         ;; only needed for future labels.
         ;; this might be a FIXME... but will we ever need that use-case?
         ;; (print-all *debug-output* "emit-label of a resolved label; laddress 0x"
         ;;            (integer->string (or (<label>-laddress label) 0) 16)
         ;;            ", paddress: 0x" (integer->string (or (<label>-paddress label) 0) 16)
         ;;            ", offset: " offset
         ;;            "\n")
         (when reloc-type
           (%record-relocation label (first reloc-type) size offset))
         (writer (+ (<label>-laddress label)
                    (or offset 0))))
      (let ((emitter (or (<label>-primed-emitter label)
                         (begin
                          ;; there's no requested calculation in a
                          ;; primed emitter, so we define a default one
                          ;; that just takes the laddress.
                          (%prime-label label (lambda (paddress laddress) laddress))
                          (<label>-primed-emitter label)))))
        ;; (print-all *debug-output* "emit-label is calling the emitter with 'state/emit; laddress 0x"
        ;;             (integer->string (or (<label>-laddress label) 0) 16)
        ;;             ", paddress: 0x" (integer->string (or (<label>-paddress label) 0) 16)
        ;;             ", offset: " offset "\n")
        (apply emitter (list 'state/emit writer offset size reloc-type))
        (push (<label>-emitters label) emitter)
        (set (<label>-primed-emitter label) ())
      (writer 0))))
  label)

(define-function emit-u8 (value)
  (typecase value
    (<long>
     (assert (<= 0 value 0xff) "emit-u8: out of range: "value)
     (let* ((segment	(current-segment))
            (buffer	(<segment>-buffer segment))
            (position	(<segment>-paddress segment)))
       ;; (print-all *debug-output* "emit-u8 is storing 0x" (integer->hex-string value) " at 0x"(integer->hex-string position)
       ;;            ", segment-length: 0x"(integer->hex-string (memory-block/length buffer))
       ;;            ", laddress: 0x"(integer->hex-string (<segment>-laddress segment))
       ;;            "\n")
       (incr (<segment>-laddress segment))
       (set (memory-block/at buffer position) value)
       (set (<segment>-paddress segment) (+ 1 position))))
    (else	(error "emit-u8: called with unexpected value: "value", type: "(type-of value)))))

(define-function emit-i8 (value)
  (typecase value
    (<long>
     (assert (if (<= 0 value) (<= value 0xff) (<= -0x80 value)) "emit-i8: out of range: "value)
     (emit-u8 (bitwise-and value 0xff)))
    (<label>	(emit-label value emit-i8 1))
    (<symbol>	(emit-i8 (%ensure-label value)))
    (else	(error "emit-i8: called with unexpected value: "value", type: "(type-of value)))))

(define-function emit-u16 (value)
  (typecase value
    (<long>
     (assert (<= 0 value 0xffff) "emit-u16: out of range: "value)
     (emit-u8 (bitwise-and 0xff value))
     (emit-u8 (bitwise-and 0xff (bitwise-shift value -8))))
    (else	(error "emit-u16: called with unexpected value: "value", type: "(type-of value)))))

(define-function emit-i16 (value)
  (typecase value
    (<long>
     (assert (<= -0x8000 value 0x7fff) "emit-i16: out of range: "value)
     (emit-u16 (bitwise-and value 0xffff)))
    (<label>	(emit-label value emit-i16 2))
    (<symbol>	(emit-i16 (%ensure-label value)))
    (else	(error "emit-i16: called with unexpected value: "value", type: "(type-of value)))))

(define-function emit-u32 (value)
  (typecase value
    (<long>
     (assert (<= 0 value 0xffffffff) "emit-u32: out of range: "value)
     (emit-u16 (bitwise-and 0xffff value))
     (emit-u16 (bitwise-and 0xffff (bitwise-shift value -16))))
    ;; (<lower-cell> TODO) needed to support 32 bit mode
    (else	(error "emit-u32: called with unexpected value: "value", type: "(type-of value)))))

(define-function emit-i32 (value)
  ;;(println "emit-i32, value: "value)
  (typecase value
    (<long>
     ;; TODO only works on 64 bit hosts
     (assert (if (<= 0 value) (<= value 0x7fffffff) (<= -0x80000000 value 0)) "emit-i32: out of range: "value)
     (emit-u32 (bitwise-and value 0xffffffff)))
    (<label>	(emit-label value emit-i32 4))
    (<symbol>	(emit-i32 (%ensure-label value)))
    ;; (<lower-cell> TODO) needed to support 32 bit mode
    (else	(error "emit-i32: called with unexpected value: "value", type: "(type-of value)))))

(define-function emit-u64 (value)
  ;;(println "emit-u64, value: "value", at laddress: " (current-laddress))
  (typecase value
    (<long>
     (emit-u32 (bitwise-and 0xffffffff value))
     (emit-u32 (bitwise-and 0xffffffff (bitwise-shift value -32))))
    (<lower-cell>
     ;; (print-all *debug-output* "emit-u64 is storing a <lower-cell>: "value
     ;;            ", at position: "(<assembler>-paddress *assembler*)"\n")
     (let ((segment (current-segment)))
       (set (memory-block/at (<segment>-buffer segment)
                            (<segment>-paddress segment))
            value)
       (incr (<segment>-paddress segment) 8)
       (incr (<segment>-laddress segment) 8)))
    (else	(error "emit-u64: called with unexpected value: "value", type: "(type-of value)))))

(define-function emit-i64 (value)
  ;;(println "emit-i64, value: "value", at laddress: " (current-laddress))
  (typecase value
    (<long>	(emit-u64 value)) ; always in range on 64 bit hosts
    (<lower-cell> (emit-u64 value))
    (<label>	(emit-label value emit-i64 8 'abs64))
    (<reloc-symbol>	(%record-relocation value 'symbol64 8 0)
                 (emit-u64 0))
    (<symbol>	(emit-i64 (%ensure-label value)))
    (else	(error "emit-i64: called with unexpected value: "value", type: "(type-of value)))))

;; some aliases
(define-function .i8  vals (map emit-i8  vals))
(define-function .i16 vals (map emit-i16 vals))
(define-function .i32 vals (map emit-i32 vals))
(define-function .i64 vals (map emit-i64 vals))

(define-function .i8/times (value times)
  (let* ((segment	(current-segment))
         (buffer	(<segment>-buffer segment))
         (position	(<segment>-paddress segment)))
    (times-do times
      (set (memory-block/at buffer position) value)
      (incr position))
    (incr (<segment>-laddress segment) times)
    (incr (<segment>-paddress segment) times)))

(define-function .ascii strs
  (list-do el strs
    (typecase el
      (<string>	(string-do char el
                  (emit-u8 char)))
      (<long>	(emit-u8 el)))))

(define-function .base (address)
  (set (current-laddress) address))

(define-function %align (address alignment filler)
  ;; (print-all *debug-output* "segment-length before alignment: 0x"
  ;;            (integer->string (segment-length (current-segment)) 16)
  ;;            ", (current-paddress): 0x" (integer->string (current-paddress) 16)
  ;;            ", (current-laddress): 0x" (integer->string (current-laddress) 16)
  ;;            "\n")
  (let ((remainder (bitwise-and address (- alignment 1)))
        (filler (if filler (car filler) 0)))
    ;; (print-all *debug-output* "aligning: 0x"(integer->string address 16)
    ;;            ", to: 0x"(integer->string alignment 16)
    ;;            ", remainder: 0x"(integer->string remainder 16)
    ;;            ", padding: 0x"(integer->string (- alignment remainder) 16)
    ;;            "\n")
    (when (< 0 remainder)
      (times-do (- alignment remainder)
        (emit-u8 filler)))
    ;; (print-all *debug-output* "segment-length after alignment: 0x"
    ;;            (integer->string (segment-length (current-segment)) 16)
    ;;            ", (current-paddress): 0x" (integer->string (current-paddress) 16)
    ;;            ", (current-laddress): 0x" (integer->string (current-laddress) 16)
    ;;            "\n")
    ))

(define-function .align (alignment . filler)
  (%align (current-laddress) alignment filler))

(define-function .palign (alignment . filler)
  (%align (current-paddress) alignment filler))
