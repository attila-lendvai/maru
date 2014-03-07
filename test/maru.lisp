(in-package :maru.test)

(defsuite (test/maru :in test))

(in-suite test/maru)

(deftest (test/eval/maru-test :auto-call nil) ()
  (load-boot.l)
  (maru/repl (asdf:system-relative-pathname :maru "../../ir-gen-c.k"))
  (read-and-run "(set *arguments* (list \"maru-test.k\"))")
  (maru/repl (asdf:system-relative-pathname :maru "../../maru.k")))
