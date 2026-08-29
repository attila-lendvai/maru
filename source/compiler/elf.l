;;; -*- mode: lisp; coding: us-ascii -*-

(define-constant +n-param-registers+		(list-length +param-registers+))
(define-constant +n-callee-saved-registers+	(list-length +callee-saved-registers+))

;; TODO ? introduce abstraction for ABIs...
(define-constant +call-frame-alignmet+
    (case (target-value target/cell-size/bits)
      (32 (case (target-value target/os)
            (darwin	16)
            (else	4)))
      (64 16)))

(define-constant +function-alignmet+ 16)

(define-function closure-code-label-desig (name)
  (if (feature emit-with-object-headers)
      (concat-symbol name '.code)
    name))

;; TODO this stinks. get rid of this or comment the why...
(define-function closure-code-label (name)
  (label (closure-code-label-desig name)))

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
    (current-value		+op/accumulator+)
    ))

(define-function new-temp-index (c)
  (with-instance-accessors c <compiler>
    (let ((i c.temp-counter))
      (incr c.temp-counter)
      (when (< c.temp-limit c.temp-counter)
        (set c.temp-limit c.temp-counter))
      i)))

(define-function new-stack-cell (-c-)
  (STACK-CELL (- 0 (* (+ 1 (new-temp-index -c-)) target/cell-size/bytes))))

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

;;;
;;; Emission
;;;

(define-form emit (instr-name . args)
  `(%emit -c- ,instr-name (list ,@(map (lambda (arg)
                                         (if (= '$ arg)
                                             '(<compiler>-current-value -c-)
                                           arg))
                                       args))))

(define-function %emit (-c- factory args)
  (let* ((instr (factory ())))
    (when (and (<= 3 *compiler-verbosity*)
               (not (is <COMMENT> instr)))
      ;; TODO move this into emit-instruction?
      (print-all *debug-output* "; EMIT of "instr", args: "args"\n"))
    (apply emit-instruction (cons -c- (cons instr args)))))

(define-form comp (obj)
  `(let ((__obj__ ,obj))
     (emit-comment 2 "COMPILE of "__obj__)
     ;;(assert (= (get-segment 'code) (current-segment)))
     (compile __obj__ -c-)
     (<compiler>-current-value -c-)))

;;;
;;; Forward declarations and generics
;;;

(define compile-expr)
(define LOAD)
(define *special-forms*)
(define compile-call-form)
(define external-trampoline-label)

(define-selector compile-object)

(define-selector compile (self -c-)
  (emit LOAD (compile-object self -c-)))

(define-selector compile-definition)

(define-selector compile-call-to)

(define-selector emit-prelude _) ; the default is NOP

;; Synthesizes the process entry point (the '_start label, i.e. what
;; e_entry points at) for platforms that define no maru-level _start
;; (e.g. libc, where the entry only needs to call main and exit). The
;; backends implement it; the default is NOP, so platforms with their
;; own _start (linux) and backends without FFI (llvm) are unaffected.
(define-function emit-entry-point-wrapper -c-)
;;;
;;; Common handlers
;;;

(define-function emit-object/C-string (self -c-)
  (emit-comment 3 "emit-object/C-string for: "self)
  (GLOBAL-ADDR
   (with-new-label 'ro-data
     (.ascii self)
     (.i8 0))))

(define-method compile-object <string> (-c-)
  (emit-object/C-string self -c-))

(define-method compile-object <undefined> (-c-)
  (LI64 (target-value false)))
