;;; -*- mode: lisp; coding: us-ascii -*-

;;; https://blog.packagecloud.io/eng/2016/04/05/the-definitive-guide-to-linux-system-calls/
;;; https://en.wikibooks.org/wiki/X86_Assembly/Interfacing_with_Linux

(define-instruction LINUX-SYSCALL (false 1 true)
  ;; TODO does this properly communicate to LLVM which registers get overwritten?
  ((pair)
   (print "	"$reg1" = call %oop asm sideeffect \"") ; sideffect means: never optimize away
   (let ((args $1)
         instr
         input-regs
         output
         clobbers)
     (case (slave-value target/arch)
       (IA-32
        ;; at most 6 args passed in regs. the rest should be spilled
        ;; to the stack, but we don't support that.
        (set instr	"int	$$0x80")
        (set input-regs	+linux/syscall/argument-registers/IA-32+)
        ;; https://stackoverflow.com/questions/47983371/why-do-x86-64-linux-system-calls-modify-rcx-and-what-does-the-value-mean
        ;; https://refspecs.linuxfoundation.org/elf/x86_64-abi-0.99.pdf
        ;; On IA-32 "A" means the edx:eax pair used together to
        ;; represent a 64-bit quantity. (i don't think we need that?)
        ;;(set output "A")
        ;; NOTE: seems like +{eax} is not a good input-output spec on x86,
        ;; i can't make it compile.
        (set output	"={eax}")
        (set clobbers	+linux/syscall/clobbered-registers/IA-32+))
       (x86-64
        (set instr	"syscall")
        (set input-regs	+linux/syscall/argument-registers/x86_64+)
        (set output	"={rax}")
        (set clobbers	+linux/syscall/clobbered-registers/x86_64+))
       (aarch64
        (set instr	"svc #0")
        (set input-regs +linux/syscall/argument-registers/aarch64+)
        ;; first arg is the syscall number in x8, cdr is the first actual arg to the syscall.
        ;; + prefix means it's both input and output reg.
        ;; TODO ? (set output	(if (cdr args) "+{x0}" "={x0}"))
        (set output	"={x0}")
        (set clobbers	+linux/syscall/clobbered-registers/aarch64+))
       (else
        (error "LLVM LINUX-SYSCALL instruction is not implemented for target/arch "(slave-value target/arch))))

     ;; limit input-regs to the number of args
     (let ((regs input-regs))
       (set input-regs ())
       (list-do arg args
         (push input-regs (pop regs)))
       (set input-regs (list-reverse! input-regs)))

     (println instr"\",")
     (print "	\""output)
     (map (lambda (_ reg)
            (assert reg)   ; this will fail for more args than regs.
            (print ", {"reg"}"))
          args input-regs)
     (while clobbers
       (print ",~{"(pop clobbers)"}"))
     ;; ~{memory} indicates that the assembly writes to arbitrary undeclared memory
     ;; locations - not only the memory pointed to by a declared indirect output.
     (print ",~{memory}\"\n	(")
     (emit/comma-separated-%oops args)
     (println ")"))))

(define-function compile/syscall (expr -c-)
  (let ((args		(cdr expr))
        (arg-locs	()))
    (while args
      (comp (pop args))
      (push arg-locs (<compiler>-current-value -c-)))
    (gen LINUX-SYSCALL (list-reverse! arg-locs))))

(set *special-forms*
     (concat-list *special-forms*
                  (list (cons (target-value syscall)
                              compile/syscall))))
