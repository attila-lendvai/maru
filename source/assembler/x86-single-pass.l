;;; -*- mode: lisp; coding: us-ascii -*-

;;; This is an assembler that can be used programmatically, and it
;;; runs in a single pass. Because of that forward labels are a bit
;;; more complex to use.

;; TODO add/merge as a primitive? what about the parent env chain?
(define-function variable-value (env name . default)
  (let ((var (defined? name env)))
    (cond
      (var
       (<variable>-value var))
      (default
       (first default))
      (error "variable-value: '"name "' is not defined in env " env))))

(define-record <assembler> ()
  (buffer     ; the output, a binary buffer
   env        ; a lexical env where the asm instructions are evaluated
   address    ; logical address
   position   ; current offset in the buffer
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
           ;; make it call'able right in the buffer
           ;; TODO
           ;;(address	(address-of (<buffer>-elements buffer)))
           (position	0)
           ))))

(define-function _B  (value)
  (let ((buffer   (<assembler>-buffer *assembler*))
        (position (<assembler>-position *assembler*)))
    (incr (<assembler>-address *assembler*))
    (set (lower/array-at buffer position) value)
    (set (<assembler>-position *assembler*) (+ 1 position))))

(define-function _W (value)
  (unless (is <long> value)
    (set value (value 'state/emit _W 2)))

  (assert (<= value 0xffff) "_W was called with value: "value)
  (_B (bitwise-and 0xff value))
  (_B (bitwise-and 0xff (bitwise-shift value -8))))

(define-function _L (value)
  (typecase value
    (<long>
     (assert (<= value 0xffffffff) "_L was called with value: "value)
     (_W (bitwise-and 0xffff value))
     (_W (bitwise-and 0xffff (bitwise-shift value -16))))
    ;; (<lower-cell> ???) to support 32 bit mode
    (else
     (_L (value 'state/emit _L 4)))))

(define-function _Q (value)
  (typecase value
    (<long>
     (_L (bitwise-and 0xffffffff value))
     (_L (bitwise-and 0xffffffff (bitwise-shift value -32))))
    (<lower-cell>
     ;; (print-all *debug-output* "_Q is storing a <lower-cell>: "value
     ;;            ", at position: "(<assembler>-position *assembler*)"\n")
     (set (lower/array-at (<assembler>-buffer *assembler*)
                          (<assembler>-position *assembler*))
          value)
     (incr (<assembler>-position *assembler*) 8)
     (incr (<assembler>-address *assembler*)  8))
    (else
     (_Q (value 'state/emit _Q 8)))))

;; rel8 offset
(define-function _D1 (value)
  (unless (is <long> value)
    (set value (value 'state/emit _D1 1)))

  (assert (and (<= -0x80 value) (<= value 0x7f)) "_D1 was called with offset larger than rel8: "value)
  (_B value))

;; rel32 offset
(define-function _D4 (value)
  (unless (is <long> value)
    (set value (value 'state/emit _D4 4)))

  (assert (and (<= -0x80000000 value) (<= value 0x7f000000)) "_D4 was called with offset larger than rel32: "value)
  (_L value))

(require "build/generated/x86-instructions.l")

(define-function current-position ()
  (<assembler>-position *assembler*))

(define-function current-address ()
  (<assembler>-address *assembler*))

(define-function .i8  vals (map _B vals))
(define-function .i16 vals (map _W vals))
(define-function .i32 vals (map _L vals))
(define-function .i64 vals (map _Q vals))

(define-function .ascii strs
  (list-do str strs
    (string-do char str
      (_B char))))

(define-function .base (address)
  (set (<assembler>-address *assembler*) address))

(define-function .align (alignment . filler)
  (let* ((address (current-address))
         (remainder (bitwise-and address (- alignment 1)))
         (filler (if filler (car filler) 0)))
    (when (< 0 remainder)
      (times-do (- alignment remainder)
        (_B filler)))))

;;;
;;; Labels
;;;
;;;
;;; Glossary:
;;;  - f prefix: forward label
;;;  - r suffix: relative offset
;;;  - ! suffix: define this label (as opposed to reading its address)
;;;  - p prefix: physical address, i.e. the buffer positiion of
;;;      the assembler. paddress vs laddress (which is unmarked in
;;;      the API: pself vs self)
;;;
;;; Once a forward label is defined, it is replaced with the resolved
;;; address. After that non-forward LABEL variants can be used to read
;;; its value.

(define-function label! (name)
  (let ((env (<assembler>-env *assembler*)))
    (environment-define env name (cons (current-position) (current-address)))))

(define-function %label-value (name)
  (variable-value (<assembler>-env *assembler*) name))

(define-function %label-value-or-die (name)
  (let ((entry (variable-value (<assembler>-env *assembler*) name)))
    (assert (is <long> (car entry)))
    (assert (is <long> (cdr entry)))
    entry))

(define-function plabel (name)
  (car (%label-value-or-die name)))

(define-function label (name)
  (cdr (%label-value-or-die name)))

(define-function %labelr (label-name state args)
  (assert (= state 'state/emit))
  (pop args)                            ; writer; we don't need it
  (let* ((env (<assembler>-env *assembler*))
         (laddress (cdr (variable-value env label-name)))
         (cell-size (pop args)))
    ;; (println "labelr triggered at address: "(<assembler>-address *assembler*), " value: " laddress)
    (- laddress
       (current-address)
       cell-size)))

(define-form labelr (name)
  `(lambda (state . args)
     (%labelr ,name state args)))

(define-function %forward-label (name value-future relative)
  (assert (symbol? name))
  (let* ((env		(<assembler>-env *assembler*))
         (hole-pos	())
         (hole-address	())
         (writer	())
         (cell-size	())
         (emitters	(variable-value env name ()))
         (emitter
           (lambda (state . args)
             (case state
               (state/emit
                ;; (println "%forward-label at address: "(<assembler>-address *assembler*)", pos: "(<assembler>-position *assembler*))
                (set hole-pos (current-position))
                (set hole-address (current-address))
                (set writer (pop args))
                (set cell-size (pop args)))
               (state/set
                (let ((paddress (pop args))
                      (laddress (pop args))
                      (saved-pos  (current-position))
                      (saved-addr (current-address)))
                  (set (<assembler>-position *assembler*) hole-pos)
                  ;; it's a forward label, so the form that calculates
                  ;; the final value must be delayed into a future (a
                  ;; closure). but now is the time to force it.
                  (let ((final-laddress (value-future paddress laddress)))
                    (when relative
                      (decr final-laddress (+ hole-address cell-size)))
                    (writer final-laddress)
                    ;; save the final value under this label's name,
                    ;; so that later the non-future LABEL accessor can
                    ;; be used to read it.
                    (environment-define env name (cons paddress laddress)))
                  (set (<assembler>-position *assembler*) saved-pos)
                  (set (<assembler>-address *assembler*)  saved-addr)))
               (else (error "unexpected state: "state))))))
    (push emitters emitter)
    (environment-define env name emitters)
    emitter))

(define-form flabel (name . args)
  (let ((value-form	(or (pop args)
                            'self)))
    `(%forward-label ,name (lambda (pself self) ,value-form) false)))

(define-form flabelr (name . args)
  (let ((value-form	(or (pop args)
                            'self)))
    `(%forward-label ,name (lambda (pself self) ,value-form) true)))

(define-function flabel! (name)
  (let* ((env	(<assembler>-env *assembler*))
         (emitters (variable-value env name))
         (position (current-position))
         (address  (current-address)))
    (list-do emitter emitters
      (emitter 'state/set position address))))
