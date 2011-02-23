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

(define *temp-grammar* (grammar '<temp-grammar> '<parser> ()))

(define-form grammar-eval (rules expr)
  ;;(println "GRAMMAR EVAL "rules" -> "expr)
  (with-map grammar-add-rule *temp-grammar* rules)
  (and expr (grammar-add-rule *temp-grammar* (list 'rule 'start expr)))
  ;;(println "GRAMMAR "*temp-grammar*)
  (peg-compile-grammar *temp-grammar*)
  (and expr *temp-grammar*))

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
      ;;(println v)
      (set v (eval v))
      ;;(println " => "v)
      )
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

{ error		=				-> (error "parse error near: "(parser-stream-context self.source)) ; }

{
  _		= [\t\n\r ]* ;

  digit		= [0123456789] ;

  number	= digit+ $#:d _ -> d ;

  value		= number ;

  factor	= value:a ( "*" _ factor:b	-> (* a b)
			  | "/" _ factor:b	-> (/ a b)
			  |			-> a
			  )
		;
  term		= factor:a ( "+" _ term:b   _	-> (+ a b)
			   | "-" _ term:b   _	-> (- a b)
			   |			-> a
			   )
		;
}

{ _ (term:t -> (println t))* "." }

3 +4
3- 4
3*3
3* 3+4 *4
.

(define-function pval (x)
  (println "EVAL: "x)
  (let ((result (eval x)))
    (println "=> "result)
    result))

(define-form with-forward (name expr)
  (eval `(define name ()))
  expr)

{
  letter	= [ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz] ;

  name		= ( letter (letter | digit)* ) @ $$ :id _	-> id ;

  value		= number
		| name:n					-> (eval n)
		;

  vardefn	= name:n "=" _ expression:e			-> (eval `(define ,n ,e)) ;

  expression	= vardefn | term ;

  statement	= _ expression:e				-> (println e) ;

  statement* "!"
}

foo = 21
bar = 2
foo * bar
!

{
  arglist	= "(" _ expression?:a ("," _ expression)*:b ")" _	-> `(,@a ,@b) ;

  funcall	= name:f arglist:a					-> `(,f ,@a) ;

  string	= "\"" (!"\"" .)* @$:s "\"" _				-> s ;

  value		= funcall | number | name | string ;

  factor	= value:a ( "*" _ factor:b				-> `(* ,a ,b)
			  | "/" _ factor:b				-> `(/ ,a ,b)
			  | "%" _ factor:b				-> `(% ,a ,b)
			  |						-> a
			  )
		;
  term		= factor:a ( "+" _ term:b   _				-> `(+ ,a ,b)
			   | "-" _ term:b   _				-> `(- ,a ,b)
			   |						-> a
			   )
		;

  imperative	= expression:e						-> `(println ,e) ;

  vardefn	= name:n "=" _ expression:e				-> `(define ,n ,e) ;

  paramlist	= "(" _ name?:a ("," _ name)*:b ")" _			-> `(,@a ,@b) ;

  fundefn	= name:f paramlist:a "=" _ expression:e			-> (let ()
									     (eval (list 'define f))
									     `(set ,f (lambda ,a ,e))) ;

  imperative	= expression:e  ( ";" _					-> e
				|					-> `(println ,e)
				)
		;

  expression	= _ ( fundefn | vardefn | term ) ;

  statement	= _ expression:e (";" _)*				-> e ;

  program	= statement*:s						-> (map eval s) ;

  program "."
}

println("here comes a program");

println("foo + bar = ", foo + bar);

double(x) = 2 * x;

double(21)

.

{
  relation	= term:a ( "<" _ term:b							-> `(< ,a ,b)
			 |								-> a
			 )
		;
  compound	= "{" _ statement*:s "}" _						-> `(let () ,@s) ;
  let		= "let" _ name:n "=" _ expression:i "in" _ expression:e			-> `(let ((,n ,i)) ,e) ;
  if		= "if" _ expression:a "then" _ expression:b "else" _ expression:c	-> `(if ,a ,b ,c) ;
  subexpr	= "(" _ expression:e ")" _						-> e ;
  expression	= _ ( compound | subexpr | let | if
		    | fundefn | vardefn | relation
		    )
		;
  program _ "."
}

let x = 10 in {
  println(x + 2);
  println(x * 2);
}

factorial(n) = {
  if n < 2
  then n
  else n * factorial(n - 1)
}

println(factorial(5))

.

{
  for		= "for" _ name:n "=" _ expression:a "to" _ expression:b "do" statement:c	-> `(let ((,n ,a))
												      (while (<= ,n ,b)
												        ,c
													(set ,n (+ ,n 1)))) ;
  expression	= _ ( compound | subexpr | let | if | for
		    | fundefn | vardefn | relation
		    )
		;
  program
}

for i = 1 to 10 do {
  for j = 1 to 10 do
    print(i * j, "	")
  println()
}

nfibs(n) =
  if n < 2
  then 1
  else nfibs(n - 1) + nfibs(n - 2) + 1

println("nfibs(15) is ", nfibs(15))
