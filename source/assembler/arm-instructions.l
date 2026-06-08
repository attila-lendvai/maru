;;;
;;; Run-time assembler for aarch64
;;;

(define asmfail error)

(with-forms
    ((define-numbered-constants ((prefix start count)
         (let ((index -1))
           `(begin
             ,@(let ((result ())
                     (i ,start))
                 (while (<= i ,count)
                   (push result
                         `(define-constant ,(string->symbol
                                             (concat-string prefix (number->string i)))
                              ,i))
                   (incr i))))))))

  ;; Registers X0..X31
  (define-numbered-constants "X" 0 31))

;; some aliases
(define FP X29)    ; frame pointer
(define LP X30)    ; link register
(define SP X31)    ; stack pointer
(define XZR X31)   ; always zero register in some opcodes

(define-form define-instruction (name args . body)
  `(define-function ,name ,args ,@body))

(define-form define-instruction/no-operand (name machine-code)
  `(define-instruction ,name () (emit-u32 ,machine-code)))

(define-form define-instructions/no-operand entries
  `(begin
     ,@(map (lambda (entry)
              `(define-instruction/no-operand ,(first entry) ,(second entry)))
            entries)))

(define-instructions/no-operand
  (NOP   0xD503201F)
  (YIELD 0xD503203F)
  (WFE   0xD503205F)
  (WFI   0xD503207F)
  (SEV   0xD503209F)
  (SEVL  0xD50320BF)
  (ISB   0xD5033FDF)
  (RET   0xD65F03C0)
  (ERET  0xD69F03E0))

(define-constant LSL-0  0)	; hw: 0
(define-constant LSL-16 1)	; hw: 1
(define-constant LSL-32 2)	; hw: 2
(define-constant LSL-48 3)	; hw: 3

;; MOV? Xd, #imm16
;; |31 |30 29|28..23|22..21|20..5 |4..0|
;; |sf |opc  |100101|hw    |imm16 |Rd  |
;; opc:	MOVN	Move NOT (bitwise NOT of immediate)	00
;;	MOVZ	Move Zero (zero out other bits)		10
;;	MOVK	Move Keep (replace a 16-bit halfword)	11
(define-instruction %MOVru16 (opc hw imm16 Rd)
  )
