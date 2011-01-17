;;; ----------------------------------------------------------------

(compile-begin)

(define printf	(extern 'printf))

;;(define-function fibs (n) (if (< n 2) 1 (+ 1 (+ (fibs (- n 1)) (fibs (- n 2))))))
;;
;;(define-form foo ())

(define-function doit (x)
  (printf "once %d\n" x)
  (return x)
  (set x (+ x x))
  (printf "more %d\n" x)
  x)
  
(define foo (lambda () (let ((z 42)) z)))

(define main
  (lambda (argc argv)
    ;;(for (i 0 10) (printf "%d\n" i))
    (printf "%d %d %d %d %d\n" (if) (if  1) (if  1 2) (if  1 2 3) (if  1 2 3 4))
    (printf "%d %d %d %d %d\n" (if) (if ()) (if () 5) (if () 5 6) (if () 5 6 7))
    ;;(printf "%d\n" (fibs 5))
    (printf "%d\n" (or  1 2 3))
    (printf "%d\n" (and 1 2 3))
    (let ((y 1 2 3 42))
      (printf "a%d\n" y)
      (set y (+ 1 y))
      (printf "b%d\n" y)
      )
    (printf "doit %d\n" (doit 42))
    0
    ))

(compile-end)
