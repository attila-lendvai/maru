;;; -*- coke -*-
;;;
;;; ./eval boot.l compile-peg-grammar.l <filename>.g ... | tee <filename>.l

(require "source/parsing/parser.l")
(require "source/parsing/peg.g.l")

(list-do grammar-file *command-line-arguments*
  (warn "compiling PEG grammar from file " grammar-file "\n")
  (let ((forms (parse-file <peg> $start grammar-file)))
    (map dumpln forms)))
