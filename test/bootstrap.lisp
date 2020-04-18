(in-package :maru/test)

(defsuite (test/bootstrap :in test) ()
  (with-fixture stage-001
    (-run-child-tests-)))

(in-suite test/bootstrap)

(deftest test/bootstrap/1 ()
  (load-boot.l)
  (maru/repl (maru-file-pathname "emit.l"))
  (maru/repl (maru-file-pathname "eval.l")))
