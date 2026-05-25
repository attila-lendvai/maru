;;; -*- mode: lisp; coding: us-ascii -*-

(define-constant +linux/syscall/argument-registers/x86_64+
    `(quote ,(list RAX RDI RSI RDX R10 R8 R9)))

;; redefine the 32 bit version
(define-instruction LINUX-SYSCALL (false 0 true)
  ((pair)
   (let ((args $1)
         (regs +linux/syscall/argument-registers/x86_64+))
     (while args
       (let ((arg (pop args))
             (reg (pop regs)))
         (typecase arg
           (<REGISTER>		(MOVQrr (<REGISTER>-name arg) reg))
           (<LI64>		(MOVQir (<LITERAL>-value arg) reg))
           (<STACK-CELL>	(MOVQmr (<STACK-CELL>-offset arg) RBP 0 0 reg))
           (else
            (error "LINUX-SYSCALL: unexpected argument type: "(type-of arg)", prints as: "arg)))))
     (SYSCALL))))

;; TODO add a <target-function> for this? or add a macro whose
;; expansion contains a literal x86 asm LINUX-SYSCALL instruction that
;; is passed through all the way to emit?
(define-function compile/syscall (expr -c-)
  (let ((args		(cdr expr))
        (arg-locs	()))
    (while args
      (push arg-locs (compile/expr-into-temp-or-literal (pop args) -c-)))
    (free-temps arg-locs)
    (emit LINUX-SYSCALL (list-reverse! arg-locs))))

;; let's not push it at the head of the assoc list, it's rarely used
(set *special-forms*
     (concat-list *special-forms*
                  (list (cons (target-value syscall)
                              compile/syscall))))
