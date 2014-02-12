(defsystem :maru.test
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.test-system"
  :depends-on (:maru
               :hu.dwim.stefil+swank)
  :components ((:module "test"
                :components ((:file "package")
                             (:file "suite" :depends-on ("package"))
                             (:file "eval" :depends-on ("suite"))
                             (:file "reading" :depends-on ("suite"))))))
