;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/assembler/single-pass.l")

(define-function emit-rel8 (value)
  ;;(println "emit-rel8, value: "value)
  (typecase value
    (<long>	(emit-i8 value))
    (<label>	(emit-label value emit-rel8 1 (- 0 (current-laddress) 1)))
    (<symbol>	(emit-rel8 (%ensure-label value)))
    (else	(error "emit-rel8: called with unexpected value: "value", type: "(type-of value)))))

(define-function emit-rel32 (value)
  ;;(println "emit-rel32, value: "value)
  (typecase value
    (<long>	(emit-i32 value))
    (<label>	(emit-label value emit-rel32 4 (- 0 (current-laddress) 4)))
    (<symbol>	(emit-rel32 (%ensure-label value)))
    (else	(error "emit-rel32: called with unexpected value: "value", type: "(type-of value)))))

(require "source/assembler/x86-instructions.l")

(define AL _AL)
(define CL _CL)
(define DL _DL)
(define BL _BL)

(define AX _AX)
(define CX _CX)
(define DX _DX)
(define BX _BX)

(define EAX _EAX)
(define ECX _ECX)
(define EDX _EDX)
(define EBX _EBX)
(define ESP _ESP)
(define EBP _EBP)
(define ESI _ESI)
(define EDI _EDI)

(define RAX _RAX)
(define RCX _RCX)
(define RDX _RDX)
(define RBX _RBX)
(define RSP _RSP)
(define RBP _RBP)
(define RSI _RSI)
(define RDI _RDI)
(define R8  _R8)
(define R9  _R9)
(define R10 _R10)
(define R11 _R11)
(define R12 _R12)
(define R13 _R13)
(define R14 _R14)
(define R15 _R15)
