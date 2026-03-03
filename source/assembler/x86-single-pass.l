;;; -*- mode: lisp; coding: us-ascii -*-

;;; This is an assembler that can be used programmatically, and it
;;; runs in a single pass. Because of that forward labels are a bit
;;; more complex to use.

;; TODO add/merge as a primitive? what about the parent env chain?
(define-function variable-value (name env . default)
  (let ((var (defined? name env)))
    (cond
      (var
       (<variable>-value var))
      (default
       (first default))
      (else (error "variable-value: '"name "' is not defined in env " env)))))

(define-record <assembler> ()
  (buffer     ; the output, a binary buffer
   env        ; a lexical env where the asm instructions are evaluated
   laddress   ; logical address
   paddress   ; physical address; i.e. current offset in the buffer
   ))

(define-function save-assembler-buffer (a filename)
  (lower/array-save (<assembler>-buffer a) filename))

(define-function assembler->function (a)
  (lower/array->lower/function (<assembler>-buffer a)))

(define *assembler*) ; TODO turn this into something else than a global variable

(define-function begin-assembling ()
  (let ((buffer (lower/array 4096)))
    (set *assembler*
         (make <assembler>
           (buffer	buffer)
           (env		(environment))
           ;; TODO for a working address-of vm-function we either need
           ;; full-cell <long>, or more generally use <lower-cell> and
           ;; introduce arithmetic for that in the interpreter. for
           ;; now we just settle for generating position independent
           ;; code for any JIT-like scenario, and when we output ELF
           ;; files, we can just set the base explicitly.
           ;;
           ;; make it call'able right in the buffer
           ;; (laddress	(address-of (<buffer>-elements buffer)))
           (paddress	0)
           ))))

;;;
;;; Labels
;;;
;;; Labels are objects that can be used two ways:
;;;
;;;   1) anonymously as objects in local variables while generating
;;;      code
;;;
;;;   2) or they can be defined into and environment that the
;;;      assembler holds for "full-program" labels referenced as
;;;      symbols and defined into this env.
;;;
;;; The API should accept both at any position and do the
;;; lookup/define as needed.
;;;
;;; Glossary:
;;;  - forward label: a label whose paddress/laddress we don't know yet.
;;;  - p prefix: physical address, i.e. the buffer positiion of the assembler.
;;;  - l prefix: logical address, i.e. where the code will run

(define-function current-paddress ()
  (<assembler>-paddress *assembler*))

(define-function current-laddress ()
  (<assembler>-laddress *assembler*))

(define-record <label> ()
  (paddress
   laddress
   primed-emitter
   emitters))

(define-function %ensure-label (name)
  (let ((label (typecase name
                 (<label>	name)
                 (<symbol>	(variable-value name (<assembler>-env *assembler*) ()))
                 ;;(else (error "%ensure-label: not a label designator: " name))
                 )))
    (unless label
      (set label (make <label>))
      (when (is <symbol> name)
        (environment-define (<assembler>-env *assembler*) name label)))
    label))

(define-function resolved-label? (label)
  (and (is <long> (<label>-paddress label))
       (is <long> (<label>-laddress label))))

(define-function %get-label (desig)
  (typecase desig
    (<symbol>	(let ((label (variable-value desig (<assembler>-env *assembler*))))
                  (assert (is <label> label))
                  label))
    (<label>	desig)
    (else (error "%get-label: not a label designator: " desig))))

(define-function %get-resolved-label (desig)
  (let ((label (typecase desig
                 (<symbol>	(%get-label desig))
                 (<label>	desig)
                 (else (error "%get-resolved-label: not a label designator: " desig)))))
    (assert (resolved-label? label))
    label))

(define-function label args
  (if args
      (let ((desig (pop args)))
        (assert (not args))
        (let ((label	(%ensure-label desig))
              (paddress	(current-paddress))
              (laddress	(current-laddress)))
          (when (or (<label>-paddress label)
                    (<label>-laddress label))
            (error "trying to define an already defined label: "desig))
          (set (<label>-paddress label) paddress)
          (set (<label>-laddress label) laddress)
          (list-do emitter (<label>-emitters label)
            (emitter 'state/set paddress laddress))
          label))
    (make <label>
      (paddress (current-paddress))
      (laddress (current-laddress)))))

(define-function paddress (name) (<label>-paddress (%get-resolved-label name)))
(define-function laddress (name) (<label>-laddress (%get-resolved-label name)))

(define-form flabel args
  (let ((name		(pop args))
        (value-form	(or (pop args)
                            'self)))
    `(%forward-label (%ensure-label ,name) (lambda (pself self) ,value-form))))

(define-function %forward-label (desig value-future)
  (let* ((label		(%ensure-label desig))
         (env		(<assembler>-env *assembler*))
         (hole-paddress	())
         (writer	())
         (offset	false)
         (emitter
           (lambda (state . args)
             (case state
               (state/emit
                ;; (println "%forward-label at address: "(current-laddress)", pos: "(current-paddress))
                (set hole-paddress (current-paddress))
                (set writer (pop args))
                (set offset (pop args)))
               (state/set
                (let ((paddress (pop args))
                      (laddress (pop args))
                      (saved-paddress (current-paddress))
                      (saved-laddress (current-laddress)))
                  (set (<assembler>-paddress *assembler*) hole-paddress)
                  ;; it's a forward label, so the form that calculates
                  ;; the final value must be delayed into a future (a
                  ;; closure). but now is the time to force it.
                  (let ((final-laddress (value-future paddress laddress)))
                    (when offset
                      (incr final-laddress offset))
                    (writer final-laddress)
                    (set (<assembler>-paddress *assembler*) saved-paddress)
                    (set (<assembler>-laddress *assembler*) saved-laddress)))
                ())
               (else (error "unexpected state: "state))))))
    (assert (not (<label>-primed-emitter label)))
    (set (<label>-primed-emitter label) emitter)
    label))

;;;
;;; Hooks for interfacing with the intruction emitters
;;;

(define-function emit-future-label (label writer size offset)
  (if (resolved-label? label)
      (writer (- (<label>-laddress label)
                 (current-laddress)
                 size))
    (let ((emitter (or (<label>-primed-emitter label)
                       (begin
                        (%forward-label label (lambda (pself self) self))
                        (<label>-primed-emitter label)))))
      (emitter 'state/emit writer offset)
      (push (<label>-emitters label) emitter)
      (set (<label>-primed-emitter label) ())
      (writer 0)))
  label)

(define-function _B  (value)
  (let ((buffer   (<assembler>-buffer *assembler*))
        (position (<assembler>-paddress *assembler*)))
    (incr (<assembler>-laddress *assembler*))
    (set (lower/array-at buffer position) value)
    (set (<assembler>-paddress *assembler*) (+ 1 position))))

(define-function _W (value)
  (typecase value
    (<long>
     (assert (<= value 0xffff) "_W was called with value: "value)
     (_B (bitwise-and 0xff value))
     (_B (bitwise-and 0xff (bitwise-shift value -8))))
    (<label>	(emit-future-label value _W 2 ()))
    (else	(error "_W: called with unexpected value: "value))))

(define-function _L (value)
  ;;(println "_L, value: "value)
  (typecase value
    (<long>
     (assert (<= value 0xffffffff) "_L was called with value: "value)
     (_W (bitwise-and 0xffff value))
     (_W (bitwise-and 0xffff (bitwise-shift value -16))))
    (<label>	(emit-future-label value _L 4 ()))
    (<symbol>	(_L (%ensure-label value)))
    ;; (<lower-cell> TODO) needed to support 32 bit mode
    (else	(error "_L: called with unexpected value: "value))))

(define-function _Q (value)
  ;;(println "_Q, value: "value)
  (typecase value
    (<long>
     (_L (bitwise-and 0xffffffff value))
     (_L (bitwise-and 0xffffffff (bitwise-shift value -32))))
    (<lower-cell>
     ;; (print-all *debug-output* "_Q is storing a <lower-cell>: "value
     ;;            ", at position: "(<assembler>-paddress *assembler*)"\n")
     (set (lower/array-at (<assembler>-buffer *assembler*)
                          (<assembler>-paddress *assembler*))
          value)
     (incr (<assembler>-paddress *assembler*) 8)
     (incr (<assembler>-laddress *assembler*) 8))
    (<label>	(emit-future-label value _Q 8 ()))
    (<symbol>	(_Q (%ensure-label value)))
    (else	(error "_Q: called with unexpected value: "value))))

;; rel8 offset
(define-function _D1 (value)
  ;;(println "_D1, value: "value)
  (typecase value
    (<long>
     (assert (and (<= -0x80 value) (<= value 0x7f)) "_D1 was called with offset larger than rel8: "value)
     (_B value))
    (<label>	(emit-future-label value _D1 1 (- 0 (current-laddress) 1)))
    (<symbol>	(_D1 (%ensure-label value)))
    (else	(error "_D1: called with unexpected value: "value))))

;; rel32 offset
(define-function _D4 (value)
  ;;(println "_D4, value: "value)
  (typecase value
    (<long>
     (assert (and (<= -0x80000000 value) (<= value 0x7f000000)) "_D4 was called with offset larger than rel32: "value)
     (_L value))
    (<label>	(emit-future-label value _D4 4 (- 0 (current-laddress) 4)))
    (<symbol>	(_D4 (%ensure-label value)))
    (else	(error "_D4: called with unexpected value: "value))))

(define _out_rip_disp32 _D4)

(require "build/generated/x86-instructions.l")

(define-function .i8  vals (map _B vals))
(define-function .i16 vals (map _W vals))
(define-function .i32 vals (map _L vals))
(define-function .i64 vals (map _Q vals))

(define-function .ascii strs
  (list-do str strs
    (string-do char str
      (_B char))))

(define-function .base (address)
  (set (<assembler>-laddress *assembler*) address))

(define-function .align (alignment . filler)
  (let* ((address (current-laddress))
         (remainder (bitwise-and address (- alignment 1)))
         (filler (if filler (car filler) 0)))
    (when (< 0 remainder)
      (times-do (- alignment remainder)
        (_B filler)))))
