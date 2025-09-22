;;; This is some LLM slop on top of the generated IA-32 assember.
;;; Temporary kludge until a proper assembler is generated for x86-64.
;;; A lot of it is nonsense, hence the many commented out parts.

(require "source/assembler/assembler.IA-32.l")

;;; --- 64-bit register constants (high nibble = 8 -> 64-bit class) ---
(define-constant _RAX 128)  ; 0
(define-constant _RCX 129)  ; 1
(define-constant _RDX 130)  ; 2
(define-constant _RBX 131)  ; 3
(define-constant _RSP 132)  ; 4
(define-constant _RBP 133)  ; 5
(define-constant _RSI 134)  ; 6
(define-constant _RDI 135)  ; 7
;; extended registers R8..R15: same low-3 bits but set bit 3 to indicate extension (value +8)
(define-constant _R8  136)  ; 8  -> encodes reg 0 with extension bit
(define-constant _R9  137)  ; 9  -> encodes reg 1 with extension bit
(define-constant _R10 138)  ; 10
(define-constant _R11 139)  ; 11
(define-constant _R12 140)  ; 12
(define-constant _R13 141)  ; 13
(define-constant _R14 142)  ; 14
(define-constant _R15 143)  ; 15

;;; --- 64-bit register helpers ---
(define-function _r8P (R) (= (_rS R) 8))        ;; is this a 64-bit register token?
(define-function _r8N (R) (bitwise-and R 7))    ;; low 3 bits: register number 0..7
(define-function _r8extP (R) (> (bitwise-and R 8) 0)) ;; true if extension bit set (r8..r15)

;;; --- emit 8-byte little-endian immediate ---
(define-function _D8 (X D)
  (let ()
    ;; emit 8 bytes, little-endian
    (_B X (bitwise-and D 255))
    (_B X (bitwise-and (bitwise-shift D -8) 255))
    (_B X (bitwise-and (bitwise-shift D -16) 255))
    (_B X (bitwise-and (bitwise-shift D -24) 255))
    (_B X (bitwise-and (bitwise-shift D -32) 255))
    (_B X (bitwise-and (bitwise-shift D -40) 255))
    (_B X (bitwise-and (bitwise-shift D -48) 255))
    (_B X (bitwise-and (bitwise-shift D -56) 255))))

;;; --- emit REX.W prefix for one-register case (set B if target is r8..r15) ---
(define-function _REXW_emit_for_reg (X R)
  (let ((base 72)) ;; 0x48 = 0b01001000 (REX with W = 1)
    (if (_r8extP R)
        (_B X (bitwise-or base 1)) ;; set B bit (lowest bit) when reg is extended
        (_B X base))))

;;; --- MOVQir: move immediate (64-bit) into 64-bit register ---
;;; encodes: REX.W [+ REX.B if rd >= r8] ; opcode = 0xB8 + (rd & 7) ; imm64 (little-endian)
(define-function MOVQir (IM RD X)
  (if (_r8P RD)
      (let ()
        (_REXW_emit_for_reg X RD)                   ;; emit REX.W (+ B if needed)
        (_B X (+ 184 (_r8N RD)))                    ;; 0xB8 + low-3-bits of rd
        (_D8 X IM))                                 ;; imm64 little-endian
      (ASMFAIL "64-bit register required for MOVQir")))

;;; --- emit REX.W prefix for reg-to-mem ---
(define-function _REXW_emit_for_rm (X RS MB MI)
  (let ((rex 72)) ;; base = 0x48 (REX.W)
    (if (_r8extP RS) (set rex (bitwise-or rex 4))) ;; REX.R = 1 if reg >= r8
    (if (and MI (_r8extP MI)) (set rex (bitwise-or rex 2))) ;; REX.X = 1 if index >= r8
    (if (and MB (_r8extP MB)) (set rex (bitwise-or rex 1))) ;; REX.B = 1 if base >= r8
    (_B X rex)))

;;; --- MOVQrm: move 64-bit register to memory (m64 <- r64) ---
;;; args: RS = source reg, MD/MB/MI/MS = memory components, X = buffer
;; (define-function MOVQrm (RS MD MB MI MS X)
;;   (if (and (_r8P RS) (or (_r8P MB) (not MB)) (or (_r8P MI) (not MI)))
;;       (let ()
;;         (_REXW_emit_for_rm X RS MB MI)             ;; REX.W (+ R/X/B as needed)
;;         (_O_Mrm X 137 (_r8N RS) MD MB MI MS))      ;; 0x89, reg=RS, r/m=memory
;;       (ASMFAIL "MOVQrm requires 64-bit operands")))

;;; --- MOVQmr: move memory (m64) into register (r64) ---
;;; args: RD = destination reg, MD/MB/MI/MS = memory components, X = buffer
(define-function MOVQmr (MD MB MI MS RD X)
  (if (and (_r8P RD)
           (or (_r8P MB) (= 0 MB))
           (or (_r8P MI) (= 0 MI)))
      (let ()
        (_REXW_emit_for_rm X RD MB MI)             ;; REX.W (+ R/X/B bits as needed)
        (_O_r_X X 139 (_r8N RD) MD MB MI MS))      ;; 0x8B, reg=RD, r/m=memory
      (ASMFAIL "MOVQmr requires 64-bit operands")))

;;; --- MOVQrr: move r64 <- r64 ---
;;; args: RS = source reg, RD = dest reg, X = buffer
;; (define-function MOVQrr (RS RD X)
;;   (if (and (_r8P RS) (_r8P RD))
;;       (let ()
;;         ;; REX.W, with R=RS extension, B=RD extension
;;         (let ((rex 72)) ;; base = 0x48 (REX.W)
;;           (if (_r8extP RS) (set rex (bitwise-or rex 4))) ;; REX.R
;;           (if (_r8extP RD) (set rex (bitwise-or rex 1))) ;; REX.B
;;           (_B X rex))
;;         ;; opcode 0x89, reg=RS, r/m=RD (mod=11 means reg addressing)
;;         (_O_Mrm X 137 (_r8N RS) (_b11) RD false 1))
;;       (ASMFAIL "MOVQrr requires 64-bit registers")))

;;; --- INCQr: increment r64 ---
;;; args: R = target register, X = buffer
;; (define-function INCQr (R X)
;;   (if (_r8P R)
;;       (let ()
;;         ;; Build REX.W prefix
;;         (let ((rex 72)) ;; 0x48 = REX.W
;;           (if (_r8extP R) (set rex (bitwise-or rex 1))) ;; REX.B
;;           (_B X rex))
;;         ;; Opcode 0xFF, ModR/M with /0 extension
;;         (_O_Mrm X 255 0 (_b11) R false 1))
;;       (ASMFAIL "INCQr requires 64-bit register")))

;;; --- ADDQrm: add r64 to [rm64] ---
;;; Arguments:
;;;   R = source register (r64)
;;;   M = memory operand (rm64)
;;;   X = buffer/stream

;; (define-function ADDQrm (R M X)
;;   ;; Emit REX prefix for 64-bit register source
;;   (_REXW_emit_for_reg X R)
;;   ;; Emit opcode 0x01 for ADD r/m64, r64
;;   (_B X 0x01)
;;   ;; Emit ModR/M (using existing _O_Mrm helper)
;;   (_O_Mrm X M R))

;;; ADDQrm: add r64 to memory operand [base + index*scale + disp]
;;; Arguments:
;;;   R   = source register (r64)
;;;   BASE = base register (can be 0 for none)
;;;   INDEX = index register (can be 0 for none)
;;;   SCALE = scale factor (1,2,4,8)
;;;   DISP  = displacement (0, 8, or 32-bit)
;;;   X   = output buffer/stream

;; (define-function ADDQrm (R BASE INDEX SCALE DISP X)
;;   ;; Emit REX prefix for 64-bit operand and possible high registers
;;   (_REXW_emit_for_rm X R BASE INDEX)
;;   ;; Opcode for ADD r/m64, r64
;;   (_B X 0x01)
;;   ;; Emit ModR/M + SIB + displacement
;;   (_O_r_X X 1 (_r8N R) BASE INDEX SCALE DISP))
