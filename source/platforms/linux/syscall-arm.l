;;; -*- mode: lisp; coding: us-ascii -*-

(define-constant +linux/syscall/argument-registers/aarch64+
    `(quote ,(list W8 X0 X1 X2 X3 X4 X5)))

(define-instruction LINUX-SYSCALL (false 0 true)
  ((pair)
   (let ((args $1)
         (regs +linux/syscall/argument-registers/aarch64+))
     (while args
       (let ((arg (pop args))
             (reg (pop regs)))
         (typecase arg
           (<REGISTER>   (MOVr reg (<REGISTER>-name arg)))
           (<LI64>       (MOVi reg (<LITERAL>-value arg)))
            (<STACK-CELL> (LDUR reg FP (<STACK-CELL>-offset arg)))
           (else
            (error "LINUX-SYSCALL: unexpected argument type: "(type-of arg)", prints as: "arg)))))
     (SVC 0))))

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
