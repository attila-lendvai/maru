;;; class

(define %class-sizes	(array))
(define %class-fields	(array))

(define-function %make-accessor (name fields offset)
  (if fields (cons `(define-form ,(concat-symbol name (concat-symbol '- (car fields))) (self) (list 'oop-at self ,offset))
		   (%make-accessor name (cdr fields) (+ 1 offset)))))

(define-function %make-accessors (name fields)
  (%make-accessor name fields 0))

(define-form define-class (name fields)
  (let ((type (%allocate-type name))
	(size (list-length fields)))
    ;;;(%print type" "name"\n")
    (set-array-at %class-sizes  type size)
    (set-array-at %class-fields type fields)
    `(let ()
       (define ,name ,type)
       ,@(%make-accessors name fields))))

(define-function new (type)
  (allocate type (array-at %class-sizes type)))

;;; 

(define-class foo (bar)
  ((foo (- bar 1))
   (bar bar)
   (baz (+ bar 1)))
  (println "foo:"foo":"bar":"baz))

(println (foo 42))
