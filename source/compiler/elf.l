;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; Compiler Infrastructure
;;;

(define-record <compiler> ()
  (level
   temp-counter
   temp-limit
   free-stack-cells
   current-value              ; the output of the previous-instruction

   fn-epilogue-label
   c-function-entries

   free-temp-regs
   clobbered-temp-regs
   ))

(define-function compiler (level)
  (make <compiler>
    (level			level)
    (temp-counter		0)
    (temp-limit			0)
    (free-temp-regs		+callee-saved-registers+)
    (clobbered-temp-regs	(array +n-callee-saved-registers+))
    (current-value		+accumulator-register+)
    ))

(define-function new-temp-index (c)
  (with-instance-accessors c <compiler>
    (let ((i c.temp-counter))
      (incr c.temp-counter)
      (when (< c.temp-limit c.temp-counter)
        (set c.temp-limit c.temp-counter))
      i)))

(define-function new-stack-cell (-c-)
  (STACK-CELL (- 0 (* (+ 1 (new-temp-index -c-)) +word-size-in-bytes+))))

(define-function alloc-reg-temp (self)
  (with-instance-accessors self <compiler>
    (if false ;; TODO self.free-temp-regs
        (let ((reg (pop self.free-temp-regs)))
          (set (array-at self.clobbered-temp-regs (<REGISTER>-index reg)) reg)
          reg)
      (or (pop (<compiler>-free-stack-cells self))
          (new-stack-cell self)))))

(define-function %free-temp (-c- obj)
  ;; FIXME this is a mess! %free-temp is called with all kinds of objects...
  (typecase obj
    (<R64>		(push (<compiler>-free-temp-regs -c-) obj))
    (<STACK-CELL>	(push (<compiler>-free-stack-cells -c-) obj))))

(define-function alloc-stack-temp (-c-)
  (or (pop (<compiler>-free-stack-cells -c-))
      (new-stack-cell -c-)))

(define-function %free-temps (-c- temps)	(list-do temp temps (%free-temp -c- temp)))
(define-form free-temp (temp)			`(%free-temp -c- ,temp))
(define-form free-temps (temp)			`(%free-temps -c- ,temp))

;; FIXME this has been neutered by the expr-queue that flattens closure emission
(define-function accessible-variable-or-die (var -c-)
  (or (global-variable? var)
      (let ((comp-level	(<compiler>-level -c-))
            (var-level	(<env>-level (<variable>-env var))))
        (when (< var-level comp-level)
          (error "cannot access variable "var", closures are not yet supported by the compiler.")))))
