;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; ./eval boot.l compile-peg-grammar.l <filename>.g ... | tee <filename>.l

(require "source/parsing/parser.l")
(require "source/parsing/peg.g.l")

(define +generated-file-warning+ "This is compiled output from a PEG grammar; editing it is unwise!")
(println ";; " +generated-file-warning+)

(while *command-line-arguments*
  (let ((grammar-file (pop *command-line-arguments*)))
    (warn "compiling PEG grammar from file " grammar-file "\n")
    (map dumpln (parse-file <peg> $start grammar-file))))
