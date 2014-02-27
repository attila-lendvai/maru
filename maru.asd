;;; -*- mode: lisp; coding: utf-8-unix -*-

(defsystem :maru
  :description "Bootstrap eval implementation for maru."
  :depends-on (:alexandria
               :anaphora
               :iterate)
  :components ((:module "source"
                :components ((:file "package")
                             (:file "utils" :depends-on ("package"))
                             (:file "logger" :depends-on ("utils"))
                             (:file "character-table" :depends-on ("package"))
                             (:file "types-early" :depends-on ("character-table" "logger"))
                             (:file "types" :depends-on ("character-table" "eval-early" "logger" "types-early"))
                             (:file "eval-early" :depends-on ("character-table" "logger" "types-early"))
                             (:file "eval" :depends-on ("character-table" "eval-early" "logger" "types"))
                             (:file "subrs" :depends-on ("eval" "logger"))
                             (:file "state" :depends-on ("eval" "subrs"))))))
