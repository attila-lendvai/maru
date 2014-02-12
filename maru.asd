;;; -*- mode: lisp; coding: utf-8-unix -*-

(defsystem :maru
  :description "Bootstrap eval implementation for maru."
  :depends-on ()
  :components ((:module "source"
                        :components ((:file "package")
                                     (:file "utils" :depends-on ("package"))
                                     (:file "logger" :depends-on ("utils"))
                                     (:file "character-table" :depends-on ("package"))
                                     (:file "eval" :depends-on ("character-table" "logger"))
                                     (:file "subrs" :depends-on ("eval" "logger"))
                                     (:file "state" :depends-on ("eval" "subrs"))))))
