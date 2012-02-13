;;; compile-dc.l									-*- coke -*-
;;;
;;; ./eval compile-dc.l <filename>.dc

(require "parser.l")
(require "test-dc.g.l")

(while *arguments*
  (let ((g (parse-file <dc> $program (next-argument))))
    (map dumpln g)))
