;;; -*- coke -*-
;;;
;;; ./eval boot.l compile-peg-grammar.l <filename>.g ... | tee <filename>.l

(require "source/parsing/parser.l")
(require "source/parsing/peg.g.l")

(while *command-line-arguments*
  (let ((grammar-file (pop *command-line-arguments*)))
    (warn "compiling PEG grammar from file " grammar-file "\n")
    (map dumpln (parse-file <peg> $start grammar-file))))
