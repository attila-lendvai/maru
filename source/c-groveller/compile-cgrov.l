;; ./eval compile-cgrov.l <filename>.cgrov

(require "source/parsing/parser.l")

(define *headers*  (array))
(define *prologue* (array))
(define *program*  (array))

(define-function do-header	(x)	(println "#include <"x">"))
(define-function do-default	(i e)	(println "#ifndef "i) (println "#define "i" "e) (println "#endif"))
(define-function do-type	(i t)	(println "typedef "t" "i";"))
(define-function do-integer	(x)	(println "  grov_int("x");"))
(define-function do-float	(x)	(println "  grov_float("x");"))
(define-function do-string	(x)	(println "  grov_string("x");"))
(define-function do-size	(i)	(println "  grov_size_align("i");"))

(define-function def-headers  (i)	(list-do x i (array-append *headers*  (list do-header  x  ))))
(define-function def-alt      (i e)		     (array-append *prologue* (list do-default i e)) )
(define-function def-type     (i t)		     (array-append *prologue* (list do-type    i t)) )
(define-function def-integers (i)	(list-do x i (array-append *program*  (list do-integer x  ))))
(define-function def-floats   (i)	(list-do x i (array-append *program*  (list do-float   x  ))))
(define-function def-strings  (i)	(list-do x i (array-append *program*  (list do-string  x  ))))
(define-function def-sizes    (i)	(list-do x i (array-append *program*  (list do-size    x  ))))

(require "source/c-groveller/cgrov.g.l")

(define-function cgrov (stream name)
  (let ((self (new <cgrov>)))
    (set (<parser>-source    self) stream)
    (set (<peg>-grammar-name self) name)
    self))

(while *command-line-arguments*
  (parse-file <cgrov> $file (pop *command-line-arguments*)))

(define-function process (arr)
  (array-do elt arr
    (let* ((emitter (car  elt))
	   (item    (cadr elt)))
      (if (= (car item) 'qualified)
	  (let ((qualifier (cadr  item))
		(value     (caddr item)))
	    (if (= qualifier 'defined?) (println "#ifdef "value) (println "#if "qualifier))
	    (emitter value)
	    (println "#endif"))
	(apply emitter (cdr elt))))))

(define +generated-file-warning+ "This is compiled output from cgrov definitions; editing it is unwise!")
(println "// " +generated-file-warning+)

(println "#include <stdio.h>")

(process *headers*)

(println "#define STR(X)		#X")
(println "#define grov_int(X)		printf(\"(define-constant %s %ld)\\n\", #X, (long)X)")
(println "#define grov_float(X)		printf(\"(define-constant %s %12e)\\n\", #X, (double)X)")
(println "#define grov_string(X)	printf(\"(define-constant %s \\\"%s\\\")\\n\", #X, STR(X))")
(println "#define grov_size(X)		printf(\"(define-constant sizeof-%s %ld)\\n\", #X, (long)sizeof(X))")
(println "#define grov_align(X)		{ struct { char _;  X x; } x;  printf(\"(define-constant alignof-%s %ld)\\n\", #X, (long)&x.x - (long)&x); }")
(println "#define grov_size_align(X)	grov_size(X); grov_align(X)")

(process *prologue*)
(println "int main() {")
(println "  printf(\";;; " +generated-file-warning+ "\\n\");")
(process *program*)
(println "  return 0;")
(println "}")
