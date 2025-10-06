;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/buffer.l")

(define asm-buffer (buffer 4096))	; binary
(define phased 1)			; non-nil if something changed in this pass
(define $$ 0)				; last .base address
(define $ 0)				; current address

(define-function _B  (value)	(buffer-append asm-buffer value) (incr $))
(define-function _W  (value)	(_B (bitwise-and 0xff value))   (_B (bitwise-and 0xff   (bitwise-shift value -8))))
(define-function _L  (value)	(_W (bitwise-and 0xffff value)) (_W (bitwise-and 0xffff (bitwise-shift value -16))))
(define-function _Q  (value)
  (_L (bitwise-and 0xffffffff value))
  (_L (bitwise-and 0xffffffff (bitwise-shift value -32))))

;; TODO these should encode RIP relative addresses
(define-function _D1 (value)	(_B value))
(define-function _D4 (value)	(_L value))

(require "build/generated/x86-instructions.l")

(define-function define-label (name value)
  (unless (= (eval name) value)
    (eval `(set ,name ,value))
    (set phased 1)))

;; address helpers
(define-function .base (addr)		(set $$ (set $ (eval addr))))
(define-form	 .def (name expr)	(define-label name (eval expr)) ())
(define-function .i8 bytes		(list-do byte bytes (_B (eval byte))))
(define-function .i16 halfs		(list-do half halfs (_W (eval half))))
(define-function .i32 longs		(list-do long longs (_L (eval long))))
(define-function .i64 quads		(list-do quad quads (_Q (eval quad))))
(define-function .ascii strings		(list-do string strings (string-do char string (_B char))))
(define-function .asciiz strings	(apply .ascii strings) (_B 0))
(define-function .align (bytes)		(let ((remainder (bitwise-and $ (- bytes 1))))
                                          (when (< 0 remainder)
                                            (times-do (- bytes remainder)
                                              (_B 0)))))

(define-function assemble (program)
  (list-do insn program
    (cond
      ((symbol? insn)		(eval (list 'define insn 0)))
      ;; ensure the variable is defined. it needs a zero init value
      ;; because of the calculations it may be involved in prior to
      ;; its definition.
      ((= '.def (car insn))	(eval (list 'define (cadr insn) 0)))))
  (set phased 1)
  (while phased
    (set phased ())
    (buffer-reset asm-buffer)
    (set $$ (set $ (address-of (<buffer>-elements asm-buffer))))
    (list-do insn program
      (cond
	((symbol? insn)		(define-label insn $))
	((pair? insn)		(eval insn))
	(else			(error "huh? "insn)))))
  (println "assembled "(buffer-length asm-buffer)" bytes"))
