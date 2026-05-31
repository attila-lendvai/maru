;;; -*- mode: lisp; coding: us-ascii -*-

;;; This is a traditional assembler that processes a static list of
;;; instructions, and emits them in multiple phases, until no labels
;;; change value.

(require "source/streams-min-late.l")
(require "source/env-min.l")

(define-record <assembler> ()
  (buffer     ; the output, a binary buffer
   env        ; a lexical env where the asm instructions are evaluated
   ))

(define-function save-assembler-buffer (a filename)
  (let ((file (file-open-or-die filename "w")))
    (lower/$put-all (file-stream file) (<assembler>-buffer a))
    (file-close-or-die file)))

(define-function assembler->function (a)
  (lower/array->lower/function (<assembler>-buffer a)))

(define *assembler*) ; TODO turn this into something else than a global variable

;; Output buffer writers used by the assembler instructions.
(define-function emit-i8  (value)
  (let ((buf (<assembler>-buffer *assembler*)))
    (set (lower/array-at buf (lower/array-length buf)) value))
  (let* ((env (<assembler>-env *assembler*))
         (current (variable-value env '$)))
    (environment-define env '$ (+ 1 current))))

(define-function emit-i16  (value)	(emit-i8  (bitwise-and 0xff       value))	(emit-i8  (bitwise-and 0xff       (bitwise-shift value -8))))
(define-function emit-i32  (value)	(emit-i16 (bitwise-and 0xffff     value))	(emit-i16 (bitwise-and 0xffff     (bitwise-shift value -16))))
(define-function emit-i64  (value)	(emit-i32 (bitwise-and 0xffffffff value))	(emit-i32 (bitwise-and 0xffffffff (bitwise-shift value -32))))

(define emit-u8  emit-i8)
(define emit-u16 emit-i16)
(define emit-u32 emit-i32)
(define emit-u64 emit-i64)

;; TODO these should encode RIP relative offsets
(define-function emit-rel8 (value)
  (print-all *debug-output* "**** TODO emit-rel8: " value "\n")
  (emit-i8 value))
(define-function emit-rel32 (value)
  (print-all *debug-output* "**** TODO emit-rel32: " value "\n")
  (emit-i32 value))

(define emit_rip_disp32 emit-rel32)

(require "source/assembler/x86-instructions.l")

(define-function .align (bytes)
  (let* ((env (<assembler>-env *assembler*))
         (remainder (bitwise-and (variable-value env '$)
                                 (- bytes 1))))
    (when (< 0 remainder)
      (times-do (- bytes remainder)
        (emit-i8 0)))))

(define-function assemble (program)
  (let* ((env		(environment *globals*))
         (buffer	())
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
      ;; reset/clear the buffer
      (set buffer (lower/array 4096))
      (set (<assembler>-buffer a) buffer)
      ;; TODO ?
      ;; (let ((addr (address-of (<buffer>-elements buffer))))
      ;;   (environment-define env '$ addr)
      ;;   (environment-define env '$$ addr))
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
                (emit-i8 (eval byte env))))
             (.i16
              (list-do half (rest instr)
                (emit-i16 (eval half env))))
             (.i32
              (list-do long (rest instr)
                (emit-i32 (eval long env))))
             (.i64
              (list-do quad (rest instr)
                (emit-i64 (eval quad env))))
             (.ascii
              (list-do string (rest instr)
                (string-do char string
                  (emit-i8 char))))
             (.asciiz
              (list-do string (rest instr)
                (string-do char string
                  (emit-i8 char))
                (emit-i8 0)))
             (else
              (eval instr env))))
          (else
           (error "unexpected asm instruction "instr)))))
    (println "assembled "(lower/array-length buffer)" bytes in "phase-counter" phases")
    a))
