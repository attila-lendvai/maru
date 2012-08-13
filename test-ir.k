(require "ir.k")

(let ((ir (ir-new <ir> ())))

  (ir-def-struct ir 'Point (list IR-INT 'x 'y))

  (ir-put ir
    (ir-def 'point (ir-struct-type ir 'Point) (ir-struct 'Point (ir-lit 42) (ir-lit 666)))

    (ir-ext 'printf (ir-function-type ir IR-INT))

    (ir-fun 'doit (ir-function-type ir IR-VOID (ir-struct-type ir 'Point))
	    (ir-arg 'p (ir-struct-type ir 'Point))
	    (ir-call (ir-get 'printf) (ir-lit "Point with x = %d and y = %d\n")
		     (ir-member 'x (ir-addr 'p))
		     (ir-member 'y (ir-addr 'p))
		     ))

    (ir-call (ir-get 'doit) (ir-get 'point))
    )

  (ir-gen-main ir)
  )
