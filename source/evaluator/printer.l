;;; -*- mode: lisp; coding: us-ascii -*-

(define-function do-dump/string (stream obj)
  (let ((cstr (get/string obj)))
    (let ((i 0)
          (c 0))
      (libc/fputs "\"" stream)
      (while (set c (char-at cstr i))
        (if (and (<= 32 c) (<= c 126))
            (case c
              (?\"	(libc/fputs "\\\"" stream))
              (?\\	(libc/fputs "\\\\" stream))
              (else	(libc/fprintf stream "%c" c)))
          (libc/fprintf stream "\\%03o" c))
        (incr i))
      (libc/fputs "\"" stream))))

(define-function error/cannot-dump-object (obj)
  (error "cannot dump "obj))

(define-function do-print (stream obj storing?)
  ;; NOTE: be prepared to handle uninitialized objects!
  (debug/identities (libc/printf "{%p}" obj))
  (with-forms ((error-if-storing (() `(when storing? (error/cannot-dump-object obj)))))
    (let ((type (type-of obj)))
      ;; TODO use typecase
      (cond
        ((= type <undefined>)		(libc/fputs "()" stream))
        ((= type <long>)		(libc/fprintf stream "%ld" (unbox <long> obj)))
        ((= type <symbol>)		(libc/fprintf stream "%s" (unbox <symbol> obj)))

        ((= type <string>)
         (if storing?
             (do-dump/string stream obj)
           (libc/fputs (get/string obj) stream)))

        ((= type <pair>)
         (libc/fputs "(" stream)
         (while (pair? obj)
           (do-print stream (get/head obj) storing?)
           (when (pair? (set obj (get/tail obj)))
             (libc/fputs " " stream)))
         (when obj
           (libc/fputs " . " stream)
           (do-print stream obj storing?))
         (libc/fputs ")" stream))

        ((= type <array>)
         (error-if-storing)
         (let ((len (array-length obj)))
           (libc/fputs "Array(" stream)
           (for (i 0 len)
             (and i (libc/fputs " " stream))
             (do-print stream (array-at obj i) storing?))
           (libc/fputs ")" stream)))

        ((= type <expr>)
         (error-if-storing)
         (libc/fputs "Expr<" stream)
         (when-at-expand feature/track-expr-names
           (aif (<expr>-name obj)
               (do-print stream it storing?)
             (libc/fputs "?" stream))
           (libc/fputs " " stream))
         (do-print stream (<expr>-parameters obj) storing?)
         (libc/fputs ">" stream))

        ((= type <form>)
         (error-if-storing)
         (libc/fputs "Form<" stream)
         (do-print stream (<form>-function obj) storing?)
         (libc/fputs "," stream)
         (do-print stream (<form>-symbol   obj) storing?)
         (libc/fputs ">" stream))

        ((= type <fixed>)
         (error-if-storing)
         (libc/fputs "Fixed<" stream)
         (do-print stream (<fixed>-function obj) storing?)
         (libc/fputs ">" stream))

        ((= type <primitive-function>)
         (error-if-storing)
         (libc/fprintf stream ".%s" (<primitive-function>-_name obj)))

        ((= type <variable>)
         (error-if-storing)
         (let ((env (<variable>-env obj)))
           (do-print stream (<variable>-name obj) storing?)
           (when env
             (libc/fputs "." stream)
             (do-print stream (<env>-level env) storing?)
             (libc/fputs "+" stream)
             (do-print stream (<variable>-index obj) storing?))))

        ((= type <env>)
         (error-if-storing)
         (let ((level		(<env>-level	obj))
               (bindings	(<env>-bindings	obj))
               (offset		(<env>-offset	obj)))
           (if (and level bindings offset)
               (libc/fprintf stream "Env<Lv%ld,Off%ld,#%ld>" (unbox <long> level) (unbox <long> offset) (array-length bindings))
             (libc/fputs "Env<>" stream))))

        ((= type <context>)
         (error-if-storing)
         (libc/fprintf stream "Context<%p>" obj))

        ((= type <module>)
         (error-if-storing)
         (if-at-expand feature/debug-info
             (libc/fprintf stream "Module<%s," (aif (<module>-name obj)
                                                   (get/string it)
                                                 "?"))
           (libc/fputs "Module<" stream))
         (do-print stream (module-env obj) storing?)
         (libc/fputs ">" stream))

        ((= type <type>)
         (error-if-storing)
         (libc/fprintf stream "Type%s" (aif (<type>-name obj)
                                           (unbox <symbol> it)
                                         "?")))

        ((= type <record>)
         (error-if-storing)
         ;; KLUDGE we need to disable accessor typecheck here, because the target universe is unaware of inheritance
         (libc/fprintf stream "Record%s" (aif (with-forms ((%accessor-typecheck ((type obj) obj)))
                                                (<type>-name obj))
                                             (unbox <symbol> it)
                                           "?")))

        (else
         (error-if-storing)
         (libc/fprintf stream "[instof:%ld]" type))))))

(define-function print		(obj) (do-print libc/stdout obj false))
(define-function println	(obj) (do-print libc/stdout obj false) (libc/fputs "\n" libc/stdout))

(define-function dump		(obj) (do-print libc/stdout obj true))
(define-function dumpln		(obj) (do-print libc/stdout obj true) (libc/fputs "\n" libc/stdout))
