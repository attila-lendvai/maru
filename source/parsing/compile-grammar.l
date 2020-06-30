;;; -*- coke -*-
;;;
;;; ./eval compile-grammar.l <filename>.g ... | tee <filename>.l

(require "source/parsing/parser.l")
(require "source/parsing/peg.l")

(list-do grammar-file *command-line-arguments*
  (warn "compiling PEG grammar in file " grammar-file "\n")
  (let ((forms (parse-file <peg> $start grammar-file)))
    (map dumpln forms)))
