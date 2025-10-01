;;; -*- mode: lisp; coding: us-ascii -*-

;;; https://blog.packagecloud.io/eng/2016/04/05/the-definitive-guide-to-linux-system-calls/
;;; https://en.wikibooks.org/wiki/X86_Assembly/Interfacing_with_Linux

(define-instruction LINUX-SYSCALL (() 1 t)
  ;; TODO does this properly communicate to LLVM which registers get overwritten?
  ((pair)
   (print "	"$reg1" = call %oop asm sideeffect \"") ; sideffect means: never optimize away
   (let (syscall regs output clobbers)
     (case (slave-value +architecture+)
       (IA-32
        ;; at most 6 args passed in regs. the rest should be spilled
        ;; to the stack, but we don't support that.
        (set syscall	"int	$$0x80")
        (set regs	+linux/syscall/argument-registers/IA-32+)
        ;; https://stackoverflow.com/questions/47983371/why-do-x86-64-linux-system-calls-modify-rcx-and-what-does-the-value-mean
        ;; https://refspecs.linuxfoundation.org/elf/x86_64-abi-0.99.pdf
        ;; On IA-32 "A" means the edx:eax pair used together to
        ;; represent a 64-bit quantity. (i don't think we need that?)
        ;;(set output "A")
        (set output	"{eax}")
        (set clobbers	+linux/syscall/clobbered-registers/IA-32+))
       (x86-64
        (set syscall	"syscall")
        (set regs	+linux/syscall/argument-registers/x86_64+)
        (set output	"{rax}")
        (set clobbers	+linux/syscall/clobbered-registers/x86_64+))
       (aarch64
        (set syscall	"svc #0")
        (set regs	+linux/syscall/argument-registers/aarch64+)
        (set output	"{x0}")
        (set clobbers	+linux/syscall/clobbered-registers/aarch64+))
       (else
        (error "LLVM LINUX-SYSCALL instruction is not implemented for +architecture+ "(slave-value +architecture+))))

     (println syscall"\", ")
     (print "	\"="output)
     (map (lambda (_ reg)
            (assert reg)   ; this will fail for more args than regs.
            (print ", {"reg"}"))
          $1 regs)
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
