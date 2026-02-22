# -*- tab-width: 8; -*-

# *.cgrov files are small scripts written in a domain-specific language
# (called "licit") that elicits non-illicit definitions of operating system
# 'magic constants' (whenever they are available) from the header files
# present on the local system.

<cgrov> : <peg> ()

blank		= [\t ] ;
eol    		= "\n""\r"* | "\r""\n"* ;
comment1	= "//" (&. !eol .)* ;
commentN	= "/*" (&. !"*/" (commentN | .))* "*/" ;
comment		= comment1 | commentN ;
_		= (blank | comment)* ;
__		= (blank | comment | eol)* ;
dnl		= (!eol .)*@$ ;

idletter	= [A-Za-z_] ;
digit		= [0-9] ;

expression	= "(" expression ")" | !")" . ;

qualifier	= "?" _								-> 'defined?
		| "(" _ expression* @$:e ")" _					-> e ;

header		= ( [a-zA-Z0-9_/.]+@$:x      _					-> x
		  | "\"" (!"\"" .)* $:x "\"" _					-> x
		  | "<"  (!">"  .)*@$:x ">"  _					-> x
		  ) _ (qualifier:q -> `(qualified ,q ,x):x)?			-> x ;

idpart		= (idletter (idletter | digit)*) @ $$ ;
identifier	= idpart:x _							-> x ;
qualified_id	= idpart:x _ (qualifier:q -> `(qualified ,q ,x):x)?		-> x ;

keyword		= !idpart _ ;

prefix		= (idletter (idletter | digit | [./])*) @ $$ ;

definition	= "header"  keyword header*:i				__	-> (def-headers  i)
		| "prefix"  keyword prefix:i				__	-> (def-prefix i)
		| "integer" keyword qualified_id*:i			__	-> (def-integers i)
		| "float"   keyword qualified_id*:i			__	-> (def-floats   i)
		| "string"  keyword qualified_id*:i			__	-> (def-strings  i)
		| "type"    keyword identifier:i _ (!eol .)*@$:t	__	-> (def-type   i t)
		| "sizes"   keyword identifier*:i _ (!eol .)*@$:t	__	-> (def-sizes    i)
		| "default" keyword identifier:i dnl:e			__	-> (def-alt    i e) ;

file		= __ definition* (!. ~"'header', 'prefix', 'integer', 'float', 'string, 'type', 'sizes', 'default'") ;
