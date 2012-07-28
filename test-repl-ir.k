(require "ir.k")

(set peg-invoke-rule peg-invoke-rule-with-recursion)

(define-function param-list-types (pl)	(map car pl))
(define-function param-list-decls (pl)	(map (lambda (p) `(ir-arg ',(cadr p) ,(car p))) pl))

(println "#include <stdint.h>")

{
  expected      = .:what -> (error what " expected near: "(parser-stream-context self.source)) ;

  blank         = [\t ] ;
  eol           = "\n""\r"* | "\r""\n"* ;
  comment1      = "//" (&. !eol .)* ;
  commentN	= "/*" (&. !"*/" (commentN | .))* "*/" ;
  comment       = comment1 | commentN ;
  _             = (blank | eol | comment)* ;

  digit         = [0-9] ;
  higit         = [0-9A-Za-z] ;
  letter        = [A-Z_a-z] ;

  uinteger      = digit+ $#:x _                                                 -> x ;
  integer       = "-"uinteger:x                                                 -> (- x)
                |    uinteger
                ;

  ufloat        = (digit+ "."digit+ ("e"digit+)?)@$:s _                         -> (string->double s) ;
  float         = "-"ufloat:x                                                   -> (- x)
                |    ufloat
                ;

  number        = float | integer ;

  char          = "\\"  ( "t"                                   ->  9
                        | "n"                                   -> 10
                        | "r"                                   -> 13
                        | "x" (higit higit) @$#16
                        | "u" (higit higit higit higit) @$#16
                        | .
                        )
                | . ;

  string        = "\"" ("\"\""->34 | !"\"" char)* $:x "\"" _			-> x ;

  idpart        = (letter (letter | digit)*) @ $$ ;
  identifier    = idpart:x !":" _                                               -> x ;

  prefix	= identifier:e							-> `(ir-get ',e)
		| number:e							-> `(ir-lit ,e)
		| string:e							-> `(ir-lit ,e)
		;

  arglist	= expression?:a (","_ expression)*:b				-> `(,@a ,@b) ;

  primary	= prefix:a ( "("_ arglist:b ")"_				-> `(ir-call ,a ,@b) :a
			   )*							-> a ;

  factor	= primary:a "*"_ factor:b					-> `(ir-mul ,a ,b)
		| primary:a "/"_ factor:b					-> `(ir-div ,a ,b)
		| primary:a "%"_ factor:b					-> `(ir-mod ,a ,b)
		| primary
		;

  term		= factor:a "+"_ term:b						-> `(ir-add ,a ,b)
		| factor:a "-"_ term:b						-> `(ir-sub ,a ,b)
		| factor
		;

  relation	= term:a "<" _ term:b						-> `(ir-lt ,a ,b)
		| term:a "<="_ term:b						-> `(ir-le ,a ,b)
		| term:a "=="_ term:b						-> `(ir-eq ,a ,b)
		| term:a "!="_ term:b						-> `(ir-ne ,a ,b)
		| term:a ">="_ term:b						-> `(ir-ge ,a ,b)
		| term:a ">" _ term:b						-> `(ir-gt ,a ,b)
		| term
		;

  expression    = "if"_ "("_ expression:a ")"_
		  "then"_ expression:b
		  "else"_ expression:c						-> `(ir-if ,a ,b ,c)
		| relation:a "="_ expression:b					-> `(ir-set ,a ,b)
		| relation
		;

  sequence	= "{"_ statement*:s "}"_					-> `(ir-seq ,@s) ;

  statement	= sequence
		| "return"_ expression:e ";"_					-> `(ir-ret ,e)
		| expression:e ";"_						-> e
		;

  type		= "int"_							-> IR-INT ;

  param		= type:t identifier:i						-> `(,t ,i) ;

  paramlist	= param?:p (","_ param)*:q					-> `(,@p ,@q) ;

  fndecl	= type:t identifier:i "("_ paramlist:p ")"_  statement:e	-> `(ir-fun ',i (ir-function-type ir ,t ,@(param-list-types p))
										      ,@(param-list-decls p)
										      ,e) ;

  definition    = "extern"_ identifier:i ";"_					-> `(ir-ext ',i (ir-function-type ir IR-INT))
		| identifier:i "="_ fndecl:e					-> `(ir-def ',i () ,e)
		|                   fndecl
		| identifier:i "="_ statement:e					-> `(ir-def ',i () ,e)
		|                   statement:e
                ;

  program       = _ (definition:d -> `(ir-put ir ,d))*:p
		    (!. | {expected "definition or expression"})		-> p ;

  # read a 'program' from the rest of the file

  program:p			-> (eval `(let ((ir (ir-new ())))
					    ,@p
					    (ir-gen-main ir)))
}

int nfibs(int n)
  return
    if (n < 2)
    then 1
    else nfibs(n - 1) + nfibs(n - 2) + 1;

extern printf;

printf("%i\n", nfibs(5));
