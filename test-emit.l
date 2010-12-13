;;; ----------------------------------------------------------------

(define printf	(extern 'printf))

(define-function fibs (n) (if (< n 2) 1 (+ 1 (+ (fibs (- n 1)) (fibs (- n 2))))))

(define-form foo ())

(define-function main ()
  (for (i 0 10) (printf "%d\n" i))
  (printf "%d %d %d %d %d\n" (if) (if  1) (if  1 2) (if  1 2 3) (if  1 2 3 4))
  (printf "%d %d %d %d %d\n" (if) (if ()) (if () 5) (if () 5 6) (if () 5 6 7))
  (printf "%d\n" (fibs 5))
  (printf "%d\n" (or  1 2 3))
  (printf "%d\n" (and 1 2 3))
  )

(compile-environment)
