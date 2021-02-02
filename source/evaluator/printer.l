;;; -*- mode: lisp; coding: us-ascii -*-

(define-function do-dump/string (stream obj)
  (let ((cstr (get/string obj)))
    (let ((i 0)
          (c 0))
      ($put stream ?\")
      (while (set c (char-at cstr i))
        (if (and (<= 32 c) (<= c 126))
            (case c
              (?\"	($put stream ?\\) ($put stream ?\"))
              (?\\	($put stream ?\\) ($put stream ?\\))
              (else	($put stream c)))
          ($put stream ?\\)
          (let ((octal (long->string* c 8)))
            (times-do (- 3 (string-length octal))
              ($put stream ?0))
            ($put-all stream octal)))
        (incr i))
      ($put stream ?\"))))

(define-function error/cannot-dump-object (obj)
  (error "cannot dump "obj))

(define-function do-print (stream obj storing?)
  ;; NOTE: be prepared to handle uninitialized objects!
  (debug/identities (libc/printf "{%p}" obj))
  (with-forms ((error-if-storing (() `(when storing? (error/cannot-dump-object obj)))))
    (let ((type (type-of obj)))
      ;; TODO use typecase
      (cond
        ((= type <undefined>)		($put-all stream (string-from-cstring "()")))
        ((= type <long>)		($put-all stream (long->string (unbox <long> obj))))
        ((= type <symbol>)		($put-all stream (<symbol>-name obj)))

        ((= type <string>)
         (if storing?
             (do-dump/string stream obj)
           ($put-all stream obj)))

        ((= type <pair>)
         ($put stream ?\( )
         (while (pair? obj)
           (do-print stream (get/head obj) storing?)
           (when (pair? (set obj (get/tail obj)))
             ($put stream ?\ )))
         (when obj
           ($put-all stream (string-from-cstring " . "))
           (do-print stream obj storing?))
         ($put stream ?\) ))

        ((= type <array>)
         (error-if-storing)
         (let ((len (array-length obj)))
           ($put-all stream (string-from-cstring "Array("))
           (for (i 0 len)
             (and i ($put stream ?\ ))
             (do-print stream (array-at obj i) storing?))
           ($put stream ?\) )))

        ((= type <expr>)
         (error-if-storing)
         ($put-all stream (string-from-cstring "Expr<"))
         (when-at-expand feature/track-expr-names
           (aif (<expr>-name obj)
               (do-print stream it storing?)
             ($put stream ?? ))
           ($put stream ?\ ))
         (do-print stream (<expr>-parameters obj) storing?)
         ($put stream ?> ))

        ((= type <form>)
         (error-if-storing)
         ($put-all stream (string-from-cstring "Form<"))
         (do-print stream (<form>-function obj) storing?)
         ($put stream ?,)
         (do-print stream (<form>-symbol   obj) storing?)
         ($put stream ?> ))

        ((= type <fixed>)
         (error-if-storing)
         ($put-all stream (string-from-cstring "Fixed<"))
         (do-print stream (<fixed>-function obj) storing?)
         ($put stream ?> ))

        ((= type <primitive-function>)
         (error-if-storing)
         ($put stream ?.)
         ($put-all stream (string-from-cstring (<primitive-function>-_name obj))))

        ((= type <variable>)
         (error-if-storing)
         (let ((env (<variable>-env obj)))
           (do-print stream (<variable>-name obj) storing?)
           (when env
             ($put stream ?.)
             (do-print stream (<env>-level env) storing?)
             ($put stream ?+)
             (do-print stream (<variable>-index obj) storing?))))

        ((= type <env>)
         (error-if-storing)
         (let ((level		(<env>-level	obj))
               (bindings	(<env>-bindings	obj))
               (offset		(<env>-offset	obj)))
           (if (and level bindings offset)
               (let ()
                 ($put-all stream (string-from-cstring "Env<Lv"))
                 (do-print stream level storing?)
                 ($put-all stream (string-from-cstring ",Off"))
                 (do-print stream offset storing?)
                 ($put-all stream (string-from-cstring ",#"))
                 (do-print stream (box <long> (array-length bindings)) storing?))
             ($put-all stream (string-from-cstring "Env<?>")))))

        ((= type <context>)
         (error-if-storing)
         ($put-all stream (string-from-cstring "Context<>")))

        ((= type <module>)
         (error-if-storing)
         ($put-all stream (string-from-cstring "Module<"))
         (when-at-expand feature/debug-info
           (do-print stream (or (<module>-name obj)
                                (string-from-cstring "?")) false)
           ($put stream ?,))
         (do-print stream (module-env obj) storing?)
         ($put stream ?>))

        ((= type <type>)
         (error-if-storing)
         ($put-all stream (string-from-cstring "Type"))
         (do-print stream (or (<type>-name obj)
                              (string-from-cstring "?")) false))

        ((= type <record>)
         (error-if-storing)
         ($put-all stream (string-from-cstring "Record"))
         ;; KLUDGE we need to disable accessor typecheck here, because the target universe is unaware of inheritance
         (do-print stream (or (with-forms ((%accessor-typecheck ((type obj) obj)))
                                (<type>-name obj))
                              (string-from-cstring "?")) false))

        (else
         (error-if-storing)
         ($put-all stream (string-from-cstring "[instof:"))
         (do-print stream (box <long> type) storing?)
         ($put stream ?\] ))))))

(define-function print (obj)
  (do-print *standard-output* obj false))

(define-function println (obj)
  (print obj)
  ($put *standard-output* ?\n))

(define-function dump (obj)
  (do-print *standard-output* obj true))

(define-function dumpln (obj)
  (dump obj)
  ($put *standard-output* ?\n))

(define-primitive-function (dump ()) _
  (list-do arg -args-
    (dump arg))
  (first -args-))

(define-primitive-function (print ()) _
  (list-do arg -args-
    (print arg))
  (first -args-))
