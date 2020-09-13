(define (printf (int	char * ...	) *) (extern printf))
(define (atoi   (int	char *		) *) (extern atoi))

(define-function fibs int ((n int))
  (return (if (< n 2) 1 (+ 1 (+ (fibs (- n 1)) (fibs (- n 2)))))))

(define-function main int ((argc int) (argv char * *))
  (for (i 1 argc)
    (let ((count (atoi (indir argv i))))
      (printf "nfibs(%d) = %d\n" count (fibs count))))
  (return 0))

(export main)
