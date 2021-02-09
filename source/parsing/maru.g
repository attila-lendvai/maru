# -*- mode: fundamental; tab-width: 8 -*-
#
# This will be the sexp grammar for parsing the *.l maru files. It will be used to generate a
# parser that can be included by the eval.l to replace the hand-written parser in it.
#
# a sexp peg example: https://gist.github.com/nightscape/3372398

equals		= "=" space ;
blank		= [\t ] ;
eol		= ("\n" "\r"*) | ("\r" "\n"*) ;
comment		= ";" (!eol .)* ;
space		= (blank | eol | comment)* ;
backquote     	= "`"  space ;
commaat     	= ",@" space ;
comma     	= ","  space ;
dollarhash	= "$#" space ;
dollardbl	= "$$" space ;
dollar		= "$"  space ;
at		= "@"  space ;
query     	= "?"  space ;
minus      	= "-"  space ;
plus      	= "+"  space ;
star      	= "*"  space ;
lparen      	= "("  space ;
rparen     	= ")"  space ;
lbrace      	= "{"  space ;
rbrace     	= "}"  space ;
dot       	= "."  space ;
digit		= [0-9] ;
higit		= [0-9A-Fa-f] ;
number		= ("-"? digit+) @$#:n space -> n ;
letter		= [A-Z_a-z] ;
idpart		= (letter (letter | digit)*) @$$ ;
identifier	= idpart:id space				-> id ;

char		= "\\"	( "t"					->  9
			| "n"					-> 10
			| "r"					-> 13
			| "x" (higit higit) @$#16
			| "u" (higit higit higit higit) @$#16
			| .
                        )
		| . ;
string		= "\""  (!"\""  char)* $:s "\""  space		-> s ;
class		= "["   (!"]"   char)* $:s "]"   space		-> s ;

grammar         = symbol:name space plus
                  definition*:rules space                       -> `(grammar-extend ,name                 ,@rules)
                | symbol:name space colon symbol:parent space
                  (lparen identifier*:fields rparen)?
                  definition*:rules space                       -> `(grammar-define ,name ,parent ,fields ,@rules)
                | definition*:d space expression?:e             -> `(grammar-eval ,d ,(car e))
                ;

symfirst	= [-!#$%&*+/:<=>@A-Z^_a-z|~] ;
symrest		= [-!#$%&*+./:0-9<=>?@A-Z^_a-z|~] ;
symbol		= (symfirst symrest*) @$$ ;
sinteger	= "0x"(higit+) @$#16
		|     (digit+) @$#
		;
sexpr		= "-" sinteger:i						-> (- i)
		| sinteger
		| symbol
		| "\""  (!"\""  char)* $:e "\""					-> e
		| "("  sexpression*:e (space dot sexpression:f)? space ")"	-> (set-list-source `(,@e ,@f) e)
		| "'"  sexpression:e						-> (list 'quote e)
		| "`"  sexpression:e						-> (list 'quasiquote e)
		| ",@" sexpression:e						-> (list 'unquote-splicing e)
		| ","  sexpression:e						-> (list 'unquote e)
		| ";" (![\n\r] .)*
		;
sexpression	= space sexpr ;

llist		= lparen expression:e rparen			-> e ;
atom		= lparen expression:e rparen			-> e
		| quotesgl sexpression:e space			-> `(match-object ,e)
		| string:e					-> `(match-string ,e)
		| class:e					-> `(match-class ,e)
		| idpart:p "-" identifier:e			-> `(match-rule-in ,p ,e)
		| identifier:e					-> `(match-rule ,e)
		| lbrace sexpression*:e space rbrace		-> `(match-rule ,@e)
		| dot						-> `(match-any)
		| arrow sexpression:e space			-> `(result-expr ,e)
		| backquote llist:e				-> `(match-list ,e)
		;
repetition	= atom :e ( query				-> `(match-zero-one ,e)  :e
			  | star				-> `(match-zero-more ,e) :e
			  | plus				-> `(match-one-more ,e)  :e
			  )?					-> e ;
conversion	= repetition :e ( at				-> `(make-span	    ,e) :e
				| dollarhash ( number:n		-> `(make-number ,n ,e) :e
					     |			-> `(make-number 10 ,e) :e
					     )
				| dollardbl			-> `(make-symbol      ,e   ) :e
				| dollar			-> `(make-string      ,e   ) :e
				| colon identifier :i		-> `(assign-result ,i ,e   ) :e
				)*				-> e ;
predicate	= pling     conversion:e			-> `(peek-not  ,e)
		| ampersand ( arrow sexpression:e space		-> `(peek-expr ,e)
			    | conversion:e			-> `(peek-for  ,e)
			    )
		| conversion ;

sequence	= predicate:p	( predicate+:q			-> `(match-all ,p ,@q)
				|				-> p
				) ;

expression	= sequence:s	( (bar sequence)+:t		-> `(match-first ,s ,@t)
				|				-> s
				) ;

parameters	= (colon identifier)* ;

definition	= space identifier:id parameters:p
		  equals expression:e ";"			-> `(,id ,e ,p) ;

definitions	= definition* ;

start		= (parser_class | definitions):result
		  ;

varname		= symbol:s space -> s ;

parser_decl	= space varname:name colon varname:parent lparen (varname*):vars rparen	-> `(,name ,parent ,vars) ;

parser_class	= parser_decl:decl
		  definition*:definitions
		  space (!. |					-> (error "error in grammar near: "(parser-stream-context self.source))
                        )
		  {gen_cola_parser (car decl) (cadr decl) (caddr decl) definitions}
		;

parser_spec	= parser_decl?:decl definition*:defns		-> `(,decl ,@defns) ;
