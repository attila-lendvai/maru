(in-package :maru.test)

(defsuite (test/reading :in test))

(in-suite test/reading)

(deftest test/reading/simple/1 ()
  (macrolet ((frob (&rest entries)
               `(progn
                  ,@(loop
                      :for entry :in entries
                      :collect `(is (valid-maru-expression? (maru/read-expression ,entry)))))))
    "nil"
    "t"
    "(t nil)"
    "(nil t)"
    "`(t ,nil)"
    "'(t nil)"
    "(1 2.0 (\"three\" 4 (5)))"))

(deftest test/reading/simple/bugs ()
  (let ((expr (maru/read-expression "'t")))
    (is (equal expr
               `(maru::|quote| maru::|t| . ,+maru/nil+))))
  (let ((expr (maru/read-expression "`(1)")))
    (is (equal expr
               `(maru::|quasiquote| (1 . ,+maru/nil+) . ,+maru/nil+))))
  (let ((expr (maru/read-expression "(require \"ir2.k\")")))
    (is (equal expr
               `(maru::|require| "ir2.k" . ,+maru/nil+))))
  (let ((expr (maru/read-expression "(let ())")))
    (is (equal expr
               `(maru::|let| ,+maru/nil+ . ,+maru/nil+)))))

(deftest test/reading/numbers/1 ()
  (is (eql (maru/read-expression "-1") -1))
  (is (equal (maru/read-expression "(- 1)")
             `(maru::- 1 . ,+maru/nil+))))


