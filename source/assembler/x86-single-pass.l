;;; -*- mode: lisp; coding: us-ascii -*-

;;; This is an assembler that can be used programmatically, and it
;;; runs in a single pass. Because of that forward labels are a bit
;;; more complex to use.

(require "source/buffer.l")
(require "source/types.l")

;; TODO add as a primitive?
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
  (buffer-save (<assembler>-buffer a) filename))

(define-function assembler->function (a)
  (pointer->target-function (<buffer>-elements (<assembler>-buffer a))))

(define *assembler*) ; TODO turn this into something else than a global variable

(define-function begin-assembling ()
  (let ((buffer (buffer 4096)))
    (set *assembler*
         (make <assembler>
           (buffer	buffer)
           (env		(environment))
           ;; make it call'able right in the buffer
           (address	(address-of (<buffer>-elements buffer)))
           (position	0)
           ))))

(define-function _B  (value)
  (let ((buffer   (<assembler>-buffer *assembler*))
        (position (<assembler>-position *assembler*)))
    (incr (<assembler>-address *assembler*))
    (set (buffer-at buffer position) value)
    (set (<assembler>-position *assembler*) (+ 1 position))))

(define-function _W  (value)	(_B (bitwise-and 0xff value))   (_B (bitwise-and 0xff   (bitwise-shift value -8))))
(define-function _L  (value)	(_W (bitwise-and 0xffff value)) (_W (bitwise-and 0xffff (bitwise-shift value -16))))
(define-function _Q  (value)
  (_L (bitwise-and 0xffffffff value))
  (_L (bitwise-and 0xffffffff (bitwise-shift value -32))))

;; TODO these should encode RIP relative offsets
(define-function _D1 (value)
  (print-all *debug-output* "**** TODO _D1: " value "\n")
  (_B value))
(define-function _D4 (value)
  (print-all *debug-output* "**** TODO _D4: " value "\n")
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

(define-function .align (bytes)
  (let* ((position (<assembler>-position *assembler*))
         (remainder (bitwise-and position (- bytes 1))))
    (when (< 0 remainder)
      (times-do (- bytes remainder)
        (_B 0)))))

(define-function label! (name)
  (let ((env (<assembler>-env *assembler*)))
    (environment-define env name (current-address))))

(define-function label (name)
  (let* ((env (<assembler>-env *assembler*))
         (value (variable-value env name)))
    (assert (is <long> value))
    value))

(define-function %forward-label (writer name value-future offset)
  (assert (symbol? name))
  (let* ((env	(<assembler>-env *assembler*))
         (hole	(+ (<assembler>-position *assembler*) offset))
         (emitters (variable-value env name ())))
    (push emitters
          (lambda (value) ; the address
            (let ((saved-pos  (<assembler>-position *assembler*))
                  (saved-addr (<assembler>-address *assembler*)))
              (set (<assembler>-position *assembler*) hole)
              (let ((final-value (value-future value)))
                (writer final-value)
                ;; register the final value at this label
                (environment-define env name value))
              (set (<assembler>-position *assembler*) saved-pos)
              (set (<assembler>-address *assembler*)  saved-addr))))
    (environment-define env name emitters))
  ;; make space for the future value, but only if no offset was specified
  (when (= 0 offset)
    (writer 0)))

(define-form flabel (writer name . args)
  (let ((offset		(if (is <long> (first args))
                            (pop args)
                          0))
        (value-form	(or (pop args)
                            'self)))
    `(%forward-label ,writer ,name (lambda (self) ,value-form) ,offset)))

(define-function flabel! (name)
  (let* ((env	(<assembler>-env *assembler*))
         (emitters (variable-value env name))
         (address (<assembler>-address *assembler*)))
    (list-do emitter emitters
      (emitter address))))
