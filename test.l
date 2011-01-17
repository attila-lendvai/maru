(define mkcounter (lambda () (let ((x 0)) (lambda () (set x (+ x 1))))))

(define a (mkcounter))
(define b (mkcounter))

(print (a)"\n")
(print (b)" "(b)"\n")
(print (a)"\n")
(print (b)" "(b)"\n")
(print (a)"\n")
(print (b)" "(b)"\n")
(print (a)"\n")
(print (b)" "(b)"\n")
