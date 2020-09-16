(define == =)
(define ASMFAIL error)

;; TODO delme, because these are actually in the gen-asm-x86.l file now, but currently
;; if we regenrate asm-x86.l from it, then the result is broken. most probably because
;; the latest version of gen-asm-x86.l was not checked in into the repo. oh well...
(define-function _s0P (x)	(= x 0))
(define-function _s1P (x)	(and (<= -128 x) (<= x 127)))
(define-function _s2P (x)	(and (<= -32768 x) (<= x 32767)))
