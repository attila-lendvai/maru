;(define x 42)
(define f
  (let ((x 42))
    (print "A x " x "\n")
    (set x 99)
    (print "B x " x "\n")
    (lambda ()
      (print "hello f " x "\n"))))
(f)
