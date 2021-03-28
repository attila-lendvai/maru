;;; -*- mode: lisp; coding: us-ascii -*-

(eval-in-target '(define linux-syscall (fixed (lambda args (print "linux-syscall encountered in interpreted code with args " args "\n") (abort)))))

(define-emit    (LINUX-SYSCALL pair)
  (let ((args	$1)
        (regs	+linux/syscall-registers/32+))
    (while args
      (println "	movl	"(pop args)", %"(pop regs))))
  (println "	int	$0x80"))

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

(set *special-forms*
     (concat-list *special-forms*
                  (list (cons (target-value linux-syscall)
                              compile/linux-syscall))))
