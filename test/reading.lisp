(in-package :maru.test)

(defsuite (test/reading :in test))

(in-suite test/reading)

(deftest test/reading/simple/1 ()
  (labels ((recurse (form)
             (etypecase form
               (cons
                (setf (car form) (recurse (car form)))
                (setf (cdr form) (recurse (cdr form)))
                form)
               (symbol
                (is (eq (symbol-package form)
                        (load-time-value (find-package :maru))))
                form)
               ((or maru/double
                    maru/string
                    maru/long)
                form))))
    (macrolet ((frob (&rest entries)
                 `(progn
                    ,@(loop
                        :for entry :in entries
                        :collect `(is (recurse (maru/read-expression ,entry)))))))
      "nil"
      "t"
      "(t nil)"
      "(nil t)"
      "`(t ,nil)"
      "'(t nil)"
      "(1 2.0 (\"three\" 4 (5)))")))

(deftest test/reading/simple/bugs ()
  (let ((expr (maru/read-expression "'t")))
    (is (= (length expr) 2)))
  (let ((expr (maru/read-expression "`(1)")))
    (is (equal expr
               '(maru::|quasiquote| (1 . maru::|nil|))))))

(deftest test/reading/numbers/1 ()
  (is (eql (maru/read-expression "-1") -1))
  (is (equal (maru/read-expression "(- 1)")
             '(maru::- 1 . maru::|nil|))))


