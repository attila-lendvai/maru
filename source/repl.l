(require "source/parsing/parser.l")
(require "source/parsing/peg-compile-forms.l")
(require "source/parsing/peg.g.l")

(define *parser-stream*)

(define-form grammar-extend (name . rules)
  (println "GRAMMAR EXTEND" rules)
  (exit 0))

(define-form grammar-define (name parent fields . rules)
  (eval `(define-class ,name ,parent ,fields))
  (peg-compile-rules name rules)
  ())

(define-class <temp-grammar> <parser> ())

;;(require "port.l")
;;(require "source/pretty-print.l")

(define-form grammar-eval (rules expr)
  ;;(println "GRAMMAR EVAL ")  (pretty-print (expand rules))
  (peg-compile-rules '<temp-grammar> rules)
  (and expr (peg-compile-rules '<temp-grammar> (list (list 'start expr))))
  ;;(println "GRAMMAR "*temp-grammar*)
  (and expr
       `(let ((_p (parser <temp-grammar> *parser-stream*)))
	  ($start _p)
	  (<parser>-result _p))))

;;(define-eval <temp-grammar> (self) ($start self *parser-stream*))

(define-function repl-parser-stream (stream prompt)
  (let ((p		(parser <peg> stream))
	(prev-stream	*parser-stream*)
	(v))
    (set *parser-stream* stream)
    (while (let ()
	     (and prompt (print prompt))
	     ($sexpression p))
      (set v (<parser>-result p))
      ;;(println "*** " v)
      (set v (eval v))
      ;;(println " => "v)
      )
    ($sspace p)
    (or (parser-stream-at-end *parser-stream*)
	(let ()
	  (print "\nsyntax error in read-eval-print near: ")
	  (while (not (parser-stream-at-end *parser-stream*))
	    (print (character->string (parser-stream-next *parser-stream*))))
	  (println "<EOF>")
	  (abort)))
    (set *parser-stream* prev-stream)
    v))

(define-function repl-stream (stream prompt)	(repl-parser-stream (parser-stream stream) prompt))
(define-function repl-file   (file prompt path)	(repl-stream (parser-input-stream (input-stream file path)) prompt))
(define-function repl-path   (path prompt)	(repl-file (or (file-open path "r") (error "cannot open: "path)) prompt path))

;; recursive require/load comes back to here...

(define-function load (name)	(repl-path name ()))

(while *command-line-arguments*
  (repl-path (pop *command-line-arguments*) ()))

(exit 0)
