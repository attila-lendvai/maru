(define (printf (int char * ...) *) (extern printf))

(define (exit (void int) *) (extern exit))

(define-function main int ((argc int) (argv char * *))
  (let ((x 10) ((l void *) got-5))	;; label-valued variable
    (printf "Label got-5 is at %p\n" got-5)
    (while (> x 0)
      (printf "%d\n" x)
      (goto (if (= x 9) got9 .not9%))	;; computed goto with label expressions
      (printf "this cannot happen\n")
      (label got9)
      (printf "GOT 9\n")
      (label .not9%)
      (if (= x 7) (goto got7) (goto not7))	;; non-computed goto statements
      (printf "this cannot happen either\n")
      (label got7)
      (printf "GOT 7\n")
      (label not7)
      (if (= x 5) (goto l))	 ;; computed goto with aribtrary expression
      (decr x)))
  (label got-5)
  (printf "GOT 5\n")

;;(let ()
;;  (define (cases void * *) (array zero one two))
;;  (goto (indir (+ cases 1)))
;;  (label zero)	(printf "you chose 0") (goto done)
;;  (label one)		(printf "you chose 1") (goto done)
;;  (label two)		(printf "you chose 2") (goto done)
;;  (label done))

  (return  0))

(export main)
