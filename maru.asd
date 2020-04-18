(defsystem :maru
  :description "Bootstrap eval implementation for maru written in Common Lisp."
  :depends-on (:alexandria
               :anaphora
               :iterate)
  :components ((:module "source"
                :components ((:file "package")
                             (:file "utils" :depends-on ("package"))
                             (:file "logger-stubs" :depends-on ("utils"))
                             (:file "character-table" :depends-on ("package"))
                             (:file "types-early" :depends-on ("character-table" "logger-stubs"))
                             (:file "types" :depends-on ("character-table" "eval-early" "logger-stubs" "types-early"))
                             (:file "eval-early" :depends-on ("character-table" "logger-stubs" "types-early"))
                             (:file "eval" :depends-on ("character-table" "eval-early" "logger-stubs" "types"))
                             (:file "subrs" :depends-on ("eval" "logger-stubs"))
                             (:file "state" :depends-on ("eval" "subrs"))))))

(defsystem :maru/test
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.test-system"
  :depends-on (:maru+hu.dwim.logger
               :hu.dwim.stefil+swank)
  :components ((:module "test"
                :components ((:file "package")
                             (:file "suite" :depends-on ("package"))
                             (:file "eval" :depends-on ("suite"))
                             (:file "bootstrap" :depends-on ("suite"))
                             (:file "reading" :depends-on ("suite"))))))
