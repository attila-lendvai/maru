;;; -*- mode: lisp; coding: us-ascii -*-

;; i386 linux syscall ABI: number in eax, arguments in ebx, ecx, edx,
;; esi, edi, ebp, entered with int $0x80.
;; https://en.wikibooks.org/wiki/X86_Assembly/Interfacing_with_Linux

(define-constant +linux/syscall/argument-registers/x86-32+
    `(quote ,(list EAX EBX ECX EDX ESI EDI EBP)))

(define-instruction LINUX-SYSCALL (false 0 true)
  ((pair)
   (let ((args $1)
         (regs +linux/syscall/argument-registers/x86-32+))
     (while args
       (let ((arg (pop args))
             (reg (pop regs)))
         (typecase arg
           (<REGISTER>		(MOVLrr (<REGISTER>-name arg) reg))
           (<LI64>		(MOVLir (<LITERAL>-value arg) reg))
           (<STACK-CELL>	(MOVLmr (<STACK-CELL>-offset arg) RBP 0 0 reg))
           (else
            (error "LINUX-SYSCALL: unexpected argument type: "(type-of arg)", prints as: "arg)))))
     (INT 0x80))))

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
