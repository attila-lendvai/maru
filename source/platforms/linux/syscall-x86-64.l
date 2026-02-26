;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/platforms/linux/syscall-i686.l")

;; redefine the 32 bit version
(define-instruction LINUX-SYSCALL (false 0 true)
  ((pair)
   (let ((args $1)
         (regs +linux/syscall/argument-registers/x86_64+))
     (while args
       (println "	mov	"(pop args)", %"(pop regs)))
     (println "	syscall"))))
