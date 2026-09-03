;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/assembler/single-pass.l")

(define-function emit-rel8 (value)
  ;;(println "emit-rel8, value: "value)
  (typecase value
    (<long>	(emit-i8 value))
    (<label>	(emit-label value emit-rel8 1 (- 0 (current-laddress) 1) 'pc8))
    (<reloc-symbol>	(error "emit-rel8: pc8 relocations against symbols are not supported: "(<reloc-symbol>-name value)))
    (<symbol>	(emit-rel8 (%ensure-label value)))
    (else	(error "emit-rel8: called with unexpected value: "value", type: "(type-of value)))))

(define-function emit-rel32 (value)
  ;;(println "emit-rel32, value: "value)
  (typecase value
    (<long>	(emit-i32 value))
    (<label>	(emit-label value emit-rel32 4 (- 0 (current-laddress) 4) 'pc32))
    (<reloc-symbol>	(%record-relocation value 'plt32 4 0)
                 (emit-i32 -4))
    (<symbol>	(emit-rel32 (%ensure-label value)))
    (else	(error "emit-rel32: called with unexpected value: "value", type: "(type-of value)))))

(require "source/assembler/x86-instructions.l")
