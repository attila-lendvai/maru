;;; -*- mode: lisp; coding: us-ascii -*-

(eval-in-target '(define linux-syscall (fixed (lambda args (print "linux-syscall encountered in interpreted code with args " args "\n") (abort)))))

;;; https://blog.packagecloud.io/eng/2016/04/05/the-definitive-guide-to-linux-system-calls/
;;; https://en.wikibooks.org/wiki/X86_Assembly/Interfacing_with_Linux

(define-instruction LINUX-SYSCALL (() 1 t)
  ;; TODO does this properly communicate to LLVM which registers get overwritten?
  ((pair)
   (println "	"$reg1" = call %oop asm sideeffect \"")
   (let ((arg-index	1)
         (clobbers	())
         mov syscall regs arg-location)
     (case (slave-value +architecture+)
       (IA-32
        (set mov	"	movl")
        (set syscall	"	int	$$0x80")
        (set arg-location ",m") ; not enough registers on i386, pass args on the stack
        (set regs	+linux/syscall-registers/32+))
       (x86-64
        (set mov	"	movq")
        (set syscall	"	syscall")
        (set arg-location ",r")
        (set regs	+linux/syscall-registers/64+)
        ;; https://stackoverflow.com/questions/47983371/why-do-x86-64-linux-system-calls-modify-rcx-and-what-does-the-value-mean
        ;; https://refspecs.linuxfoundation.org/elf/x86_64-abi-0.99.pdf
        ;; "The kernel destroys registers %rcx and %r11."
        (push clobbers "rcx")
        (push clobbers "r11"))
       (else
        (error "LLVM LINUX-SYSCALL instruction is not implemented for +architecture+ "(slave-value +architecture+))))
     (list-do _ $1
       (let ((reg (pop regs)))
         (push clobbers reg)
         (println mov"	$"arg-index", %"reg)
         (incr arg-index)))
     (println syscall"\", ")
     (print "	\"=A")
     (list-do _ $1
       (print arg-location))
     ;; list clobbered registers
     (while clobbers
       (print ",~{"(pop clobbers)"}"))
     ;; ~{memory} indicates that the assembly writes to arbitrary undeclared memory
     ;; locations - not only the memory pointed to by a declared indirect output.
     (print ",~{memory}\"\n	(")
     (emit/comma-separated-%oops $1)
     (println ")"))))

(define-function compile/linux-syscall (expr -c-)
  (let ((args		(cdr expr))
        (arg-locs	()))
    (while args
      (comp (pop args))
      (push arg-locs (<compiler>-current-value -c-)))
    (gen LINUX-SYSCALL (list-reverse! arg-locs))))

(set *special-forms*
     (concat-list *special-forms*
                  (list (cons (target-value linux-syscall)
                              compile/linux-syscall))))
