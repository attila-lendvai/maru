(in-package :maru/test)

(defsuite (test/eval :in test))

(in-suite test/eval)

(deftest test/eval/binding/1 ()
  (let ((bound (maru/intern "bound"))
        (unbound (maru/intern "zork"))
        (env (global-namespace-of *eval-context*)))
    (maru/define env bound 42)
    (is (eql 42 (maru/cdr (maru/find-variable env bound))))
    (is (eql nil (maru/find-variable env unbound)))
    (signals error (maru/find-variable env unbound :otherwise :error))
    (values)))

(deftest test/eval/binding/2 ()
  (signals error (read-and-run "(let (2))"))
  (is (eql 42 (read-and-run "(let ((a 42)) a)")))
  (is (eql 42 (read-and-run "(let ((a 40) (b 2)) (+ a b))"))))

(deftest test/eval/predefined-subrs ()
  (let ((env (global-namespace-of *eval-context*)))
    (is (maru/find-variable env (maru/intern "+")))
    (is (null (maru/find-variable env (maru/intern "zork") :otherwise nil)))
    (values)))

(deftest test/eval/expand/simple ()
  (let ((form (maru/read-expression "(define unit-testing? '(t))")))
    (is (equal form
               (maru/expand form (global-namespace-of *eval-context*))))))

(deftest test/eval/simple/1 ()
  (is (eql (maru/intern "t") (read-and-run "'t")))
  (is (eql (maru/intern "nil") (read-and-run "'nil")))
  (is (eql +maru/nil+ (read-and-run "()")))
  (is (eql (global-namespace-of *eval-context*) (read-and-run "*globals*")))
  (is (eql 4 (read-and-run "(+ 2 2)")))
  (is (eql 42 (read-and-run "(if 't 42)")))
  (is (eql 42 (read-and-run "(if 'nil 42 43)"))) ; yes, nil is just a symbol, which is true
  (is (eql 44 (read-and-run "(if () 42 43 44)"))) ; this is the way to denote the real nil concept/abstraction
  (is (eql 45 (read-and-run "(or () 45)")))
  (is (eql 46 (read-and-run "(and 'nil 46)")))
  (is (eql (maru/intern "t") (read-and-run "(and)")))
  (is (eql +maru/nil+ (read-and-run "(or)")))
  (finishes (read-and-run "(define unit-testing? '(t))")))

(deftest test/eval/simple/2 ()
  (load-boot.l)
  (is (equal "lm"
             (read-and-run "(string-copy \"alma\" 1 2)")))
  (is (equal "alma"
             (read-and-run "(string-copy \"alma\")")))
  (is (equal "almakortebanan"
             (read-and-run "(concat-strings \"alma\" \"korte\" \"banan\")")))
  (is (equal 'maru::|almakortebanan|
             (read-and-run "(concat-symbols 'alma 'korte 'banan)")))
  (let ((ref (maru/read-expression "(1 2 3)")))
    (is (equal ref
               (read-and-run "(list 1 2 3)")))
    (is (equal ref
               (read-and-run "(concat-list (list 1) (list 2 3))")))
    (is (equal (maru/bool t)
               (read-and-run "(pair? (list 1 2 3))")))
    (is (equal (maru/bool nil)
               (read-and-run "(pair? 42)")))
    (is (equal ref
               (read-and-run "((lambda () (list 1 2 3)))")))
    (is (equal ref
               (read-and-run "(let (foo) (set foo ((lambda () (list 1 2 3)))) foo)"))))
  (is (equal (read-and-run "
 (let ((i 3)
       (j 0))
   (while (> i 0)
     (set i (- i 1))
     (set j (+ j 1)))
   j)")
             3))
  (let ((array (read-and-run "
 (let ((a (array))
       (i 0))
   (while (<= i 6)
     (set (array-at a i) i)
     (set i (+ i 1)))
   a)")))
    (is (equalp (maru/array/elements array)
                (make-array 8 :initial-contents `(0 1 2 3 4 5 6 ,+maru/nil+))))
    (is (= 7 (maru/array/size array))))
  (is (equal (maru/bool nil)
             (read-and-run "(string-begins-with \"123\" \"1234\")")))
  (is (equal (maru/bool t)
             (read-and-run "(string-begins-with \"1234\" \"1234\")")))
  (is (equal (maru/bool t)
             (read-and-run "(string-begins-with \"12345\" \"1234\")"))))

(deftest test/eval/simple/arithmetic/1 ()
  (load-boot.l)
  (is (equal (maru/bool t)
             (read-and-run "(= 1 1)")))
  (is (equal (maru/bool t)
             (read-and-run "(<= 1 1)")))
  (is (equal (maru/bool t)
             (read-and-run "(< 1 2)")))
  (is (equal (maru/bool t)
             (read-and-run "(>= 1 1)")))
  (is (equal (maru/bool t)
             (read-and-run "(> 2 1)")))
  (is (equal (maru/read-expression "(1 2 3)")
             (read-and-run "(let ((x 1) (y 1) (z 3)) (set y (+ y 1)) (list x y z))"))))

(deftest test/eval/types/1 ()
  (macrolet
      ((frob (&body entries)
         `(progn
            ,@(loop
                :for entry :in entries
                :collect `(is (eql (read-and-run ,(first entry))
                                   ,(second entry)))))))
    (frob
     ("(type-of 'nil)"           +maru/type-index/symbol+)
     ("(type-of ())"             +maru/type-index/undefined+)
     ;; TODO ("(allocate 42)" +maru/type-index/data+)
     ("(type-of 42)"             +maru/type-index/long+)
     ("(type-of 42.43)"          +maru/type-index/double+)
     ("(type-of \"str\")"        +maru/type-index/string+)
     ("(type-of 'sym)"           +maru/type-index/symbol+)
     ("(type-of (cons () ()))"   +maru/type-index/pair+)
     ("(type-of (array 1))"      +maru/type-index/array+)
     ;; TODO                     +maru/type-index/expr+
     ("(type-of (form 42))"      +maru/type-index/form+)
     ("(type-of let)"            +maru/type-index/fixed+)
     ("(type-of +)"              +maru/type-index/subr+))))

(deftest test/eval/bug/1 ()
  ;; verbatim from boot.l
  (with-logger-level (maru +warn+)
    (read-and-run "(define list (lambda args args))")
    (read-and-run "(define cadr (lambda (x) (car (cdr x))))")
    (read-and-run "(define concat-list
  (lambda (x y)
    (if (pair? x)
	(cons (car x) (concat-list (cdr x) y))
      y)))")
    (read-and-run "(define quasiquote
  (form
    (let ((qq-list) (qq-element) (qq-object))
      (set qq-list (lambda (l)
		     (if (pair? l)
			 (let ((obj (car l)))
			   (if (and (pair? obj) (= (car obj) 'unquote-splicing))
			       (if (cdr l)
				   (list 'concat-list (cadr obj) (qq-list (cdr l)))
				 (cadr obj))
			     (if (and (= 'unquote obj) (pair? (cdr l)) (not (cddr l)))
				 (cadr l)
			       (list 'cons (qq-object obj) (qq-list (cdr l))))))
		       (list 'quote l))))
      (set qq-element (lambda (l)
			(let ((head (car l)))
			  (if (= head 'unquote)
			      (cadr l)
			    (qq-list l)))))
      (set qq-object (lambda (object)
		       (if (pair? object)
			   (qq-element object)
			 (list 'quote object))))
      (lambda (expr)
	(qq-object expr)))))"))
  (dolist (entry '(("(foo 42)"
                    "`(foo ,42)")
                   ("(1 2 3 4)"
                    "`(1 ,@(list 2 3) 4)")
                   ("(1 2 3)"
                    "`(1 2 3)")
                   ("(1 2 3)"
                    "`(1 2 ,3)")))
    (let ((expr1 (maru/read-expression (first entry)))
          (expr2 (maru/read-expression (second entry))))
      (is (equal expr1 (maru/eval (maru/expand expr2)))))))

(deftest test/eval/bug/2 ()
  (load-boot.l)
  (with-logger-level (maru +warn+)
    (let* ((expr (maru/read-expression "(set (cdr tail) 42)"))
           (expanded (maru/expand expr (global-namespace-of *eval-context*))))
      (is (equal expanded
                 '(maru::|set-cdr| maru::|tail| 42 . #.+maru/nil+))))))

(deftest test/eval/bug/3 ()
  (load-boot.l)
  (is (equal `(2 3 . ,+maru/nil+)
             (read-and-run "
 (let ((x (lambda args
            (set args (cdr args))
            args)))
   (x 1 2 3))")))
  (is (equal `(maru::|c| maru::|b| . ,+maru/nil+)
             (read-and-run "
 (let* ((x ())
        (fn (lambda args
              (while (symbol? (car (set args (cdr args))))
                (set x (cons (car args) x))))))
   (fn 'a 'b 'c)
   x)")))
  (is (equal 'maru::|almakortebanan|
             (read-and-run "(concat-symbols 'alma 'korte 'banan)"))))
