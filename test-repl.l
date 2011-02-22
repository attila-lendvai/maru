;; (require "parser.l")
;; (require "peg-compile.l")
;; (require "peg.l")

(define *parser-stream*)

(define-form grammar-extend (name . rules)
  (println "GRAMMAR EXTEND" rules)
  ())

(define-form grammar-extend (name parent . rules)
  (println "GRAMMAR DEFINE" rules)
  ())

(define-form grammar-eval (rules expr)
  (println "GRAMMAR EVAL "rules" -> "expr)
  (let ((g (grammar '<*inline*> '<parser> ())))
    (with-map grammar-add-rule g rules)
    (and expr (grammar-add-rule g (list 'rule 'start expr)))
    (println "GRAMMAR "g)
    (peg-compile-grammar g)
    g))
;;    `($start (parser <*inline*> *parser-stream*))))

(define-eval <grammar> (self) ($start (parser (<grammar>-type self) *parser-stream*)))

(define-function repl-parser-stream (stream prompt)
  (let ((p (parser <peg> stream))
	(s *parser-stream*)
	(v))
    (set *parser-stream* stream)
    (while (let ()
	     (and prompt (print prompt))
	     ($sexpression p))
      (set v (<parser>-result p))
      (println v)
      (set v (eval v))
      (println " => "v))
    (set *parser-stream* s)
    v))

(define-function repl-stream (stream prompt)	(repl-parser-stream (parser-stream stream) prompt))
(define-function repl-file   (file prompt)	(repl-stream (input-stream file) prompt))
(define-function repl-path   (path prompt)	(repl-file (or (open path) (error "cannot open: "path)) prompt))

(repl-file *input* ())

;;;----------------------------------------------------------------

(define-selector twice)

(define-method twice <long> () (+ self self))

(println (twice 21))

(println "HERE IT IS " '{ foo })

{ error		=					-> (error "parse error near: "(parser-stream-context self.source)) ;
  _		= [\t\n\r ]* ;
  digit		= [0123456789] ;
  number	= digit+ $#:d _ -> d ;
  factor	= number:a ( "*" _ factor:b	-> (* a b)
			   | "/" _ factor:b	-> (/ a b)
			   | "%" _ factor:b	-> (% a b)
			   |			-> a
			   )
		;
  term		= factor:a ( "+" _ term:b   _	-> (+ a b)
			   | "-" _ term:b   _	-> (- a b)
			   |			-> a
			   )
		;
  statement	= _ term:t			-> (println "RESULT "(eval t)) ;
  statement*
}

3 +4
3- 4
3*3
3* 3+4 *4
