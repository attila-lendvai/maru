;;; -*- mode: lisp; coding: us-ascii -*-

(define-instruction LINUX-SYSCALL (false 0 true)
  ((pair)
   (let ((args $1)
         (regs +linux/syscall/argument-registers/IA-32+))
     ;; at most 6 args passed in regs. the rest should be spilled
     ;; to the stack, but we don't support that.
     ;; https://stackoverflow.com/questions/47983371/why-do-x86-64-linux-system-calls-modify-rcx-and-what-does-the-value-mean
     ;; https://refspecs.linuxfoundation.org/elf/x86_64-abi-0.99.pdf
     (while args
       (println "	mov	"(pop args)", %"(pop regs)))
     (println "	int	$0x80"))))

;; TODO add a <target-function> for this? or add a macro whose
;; expansion contains a literal x86 asm LINUX-SYSCALL instruction that
;; is passed through all the way to emit?
(define-function compile/linux-syscall (expr -c-)
  (let ((args		(cdr expr))
        (arg-locs	()))
    (while args
      (push arg-locs (compile/expr-into-temp-or-literal (pop args) -c-)))
    (free-temps arg-locs)
    (gen LINUX-SYSCALL (list-reverse! arg-locs))))

;; let's not push it at the head of the assoc list, it's rarely used
(set *special-forms*
     (concat-list *special-forms*
                  (list (cons (target-value linux-syscall)
                              compile/linux-syscall))))
