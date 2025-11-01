;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/buffer.l")
(require "source/types.l")

;; TODO add as a primitive?
(define-function variable-value (env name)
  (<variable>-value (defined? name env)))

(define-record <assembler> ()
  (buffer     ; the output, a binary buffer
   env        ; a lexical env where the asm instructions are evaluated
   ))

(define-function save-assembler-buffer (a filename)
  (buffer-save (<assembler>-buffer a) filename))

(define-function assembler->function (a)
  (pointer->target-function (<buffer>-elements (<assembler>-buffer a))))

(define *assembler*) ; TODO turn this into something else than a global variable

;; Output buffer writers used by the generated assembler instructions.
(define-function _B  (value)
  (buffer-append (<assembler>-buffer *assembler*) value)
  (let* ((env (<assembler>-env *assembler*))
         (current (variable-value env '$)))
    (environment-define env '$ (+ 1 current))))

(define-function _W  (value)	(_B (bitwise-and 0xff value))   (_B (bitwise-and 0xff   (bitwise-shift value -8))))
(define-function _L  (value)	(_W (bitwise-and 0xffff value)) (_W (bitwise-and 0xffff (bitwise-shift value -16))))
(define-function _Q  (value)
  (_L (bitwise-and 0xffffffff value))
  (_L (bitwise-and 0xffffffff (bitwise-shift value -32))))

;; TODO these should encode RIP relative offsets
(define-function _D1 (value)	(_B value))
(define-function _D4 (value)	(_L value))

(require "build/generated/x86-instructions.l")

(define-function .align (bytes)
  (let* ((env (<assembler>-env *assembler*))
         (remainder (bitwise-and (variable-value env '$)
                                 (- bytes 1))))
    (when (< 0 remainder)
      (times-do (- bytes remainder)
        (_B 0)))))

(define-function assemble (program)
  (let* ((env		(environment *globals*))
         (buffer	(buffer 4096))
         (a		(make <assembler>
                          (buffer	buffer)
                          (env		env)))
         (phased	true)
         (phase-counter	0))

    (set *assembler* a) ; TODO

    ;; ensure that the necessary variables get defined
    (list-do instr program
      (cond
        ((symbol? instr)
         ;;(println "Predefining label '"instr"'")
         (environment-define env instr 0))
        ;; it needs a zero init value because of the calculations it
        ;; may be involved in prior to its definition.
        ((= '.def (first instr))	(environment-define env (cadr instr) 0))))

    ;; run the phased assembly, as many times as anything changes
    (while phased
      (incr phase-counter)
      ;;(println "Running phase "phase-counter)
      (set phased false)
      (buffer-reset buffer)
      (let ((addr (address-of (<buffer>-elements buffer))))
        (environment-define env '$ addr)
        (environment-define env '$$ addr))
      (list-do instr program
        ;;(println "Instruction: "instr)
        (typecase instr
          (<symbol>             ; a single symbol: treat it as a label
           (let ((label-name instr)
                 (current-address (variable-value env '$)))
             (unless (= (variable-value env label-name) current-address)
               (environment-define env label-name current-address)
               (set phased true))))
          (<pair>
           (case (first instr)
             (.def
              (let ((name (second instr))
                    (expr (third instr)))
                (eval `(set ,name ,expr) env)))
             (.base
              (let ((addr (eval (second instr) env)))
                (environment-define env '$$ addr)
                (environment-define env '$ addr)))
             (.i8
              (list-do byte (rest instr)
                (_B (eval byte env))))
             (.i16
              (list-do half (rest instr)
                (_W (eval half env))))
             (.i32
              (list-do long (rest instr)
                (_L (eval long env))))
             (.i64
              (list-do quad (rest instr)
                (_Q (eval quad env))))
             (.ascii
              (list-do string (rest instr)
                (string-do char string
                  (_B char))))
             (.asciiz
              (list-do string (rest instr)
                (string-do char string
                  (_B char))
                (_B 0)))
             (else
              (eval instr env))))
          (else
           (error "unexpected asm instruction "instr)))))
    (println "assembled "(buffer-length buffer)" bytes in "phase-counter" phases")
    a))
