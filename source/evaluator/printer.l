;;; -*- mode: lisp; coding: us-ascii -*-

(define-function do-dump/string (stream obj)
  ($put stream ?\")
  (string-do c obj
    (if (and (<= 32 c) (<= c 126))
        (case c
          (?\"	($put stream ?\\) ($put stream ?\"))
          (?\\	($put stream ?\\) ($put stream ?\\))
          (else	($put stream c)))
      ($put stream ?\\)
      (let ((octal (long->string* c 8)))
        (times-do (- 3 (string-length octal))
          ($put stream ?0))
        ($put-all stream octal))))
  ($put stream ?\"))

(define-function error/cannot-dump-object (obj)
  (error "cannot dump "obj))

(define-function do-print (stream obj storing?)
  ;; NOTE: be prepared to handle uninitialized objects!
  (debug/identities (libc/printf "{%p}" obj))
  (with-forms ((error-if-storing (() `(when storing? (error/cannot-dump-object obj)))))
    (let ((type (type-of obj)))
      ;; TODO use typecase
      (cond
        ((= type <undefined>)		($put-all stream "()"))
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
           ($put-all stream " . ")
           (do-print stream obj storing?))
         ($put stream ?\) ))

        ((= type <array>)
         (error-if-storing)
         (let ((len (array-length obj)))
           ($put-all stream "Array(")
           (for (i 0 len)
             (and i ($put stream ?\ ))
             (do-print stream (array-at obj i) storing?))
           ($put stream ?\) )))

        ((= type <expr>)
         (error-if-storing)
         ($put-all stream "Expr<")
         (when-at-expand feature/track-expr-names
           (aif (<expr>-name obj)
               (do-print stream it storing?)
             ($put stream ?? ))
           ($put stream ?\ ))
         (do-print stream (<expr>-parameters obj) storing?)
         ($put stream ?> ))

        ((= type <form>)
         (error-if-storing)
         ($put-all stream "Form<")
         (do-print stream (<form>-function obj) storing?)
         ($put stream ?,)
         (do-print stream (<form>-symbol   obj) storing?)
         ($put stream ?> ))

        ((= type <fixed>)
         (error-if-storing)
         ($put-all stream "Fixed<")
         (do-print stream (<fixed>-function obj) storing?)
         ($put stream ?> ))

        ((= type <target-function>)
         (error-if-storing)
         ($put stream ?.)
         ;; TODO handle name as optional
         ($put-all stream (<target-function>-name obj)))

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
                 ($put-all stream "Env<Lv")
                 (do-print stream level storing?)
                 ($put-all stream ",Off")
                 (do-print stream offset storing?)
                 ($put-all stream ",#")
                 (do-print stream (box <long> (array-length bindings)) storing?))
             ($put-all stream "Env<?>"))))

        ((= type <context>)
         (error-if-storing)
         ($put-all stream "Context<>"))

        ((= type <module>)
         (error-if-storing)
         ($put-all stream "Module<")
         (when-at-expand feature/debug-info
           (do-print stream (or (<module>-name obj) "?") false)
           ($put stream ?,))
         (do-print stream (module-env obj) storing?)
         ($put stream ?>))

        ((= type <type>)
         (error-if-storing)
         ($put-all stream "Type")
         (do-print stream (or (<type>-name obj) "?") false))

        ((= type <record>)
         (error-if-storing)
         ($put-all stream "Record")
         ;; KLUDGE we need to disable accessor typecheck here, because the target universe is unaware of inheritance
         (do-print stream (or (with-forms ((%accessor-typecheck ((type obj) obj)))
                                (<type>-name obj))
                              "?")
           false))

        (else
         (error-if-storing)
         ($put-all stream "[instof:")
         (do-print stream (box <long> type) storing?)
         ($put stream ?\] )))))
  obj)

;; TODO this smells like something that could be further simplified
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

(define-primitive-function (dump-all ()) _
  (let ((stream (pop -args-)))
    (list-do arg -args-
      (do-print stream arg true))))

;; NOTE there's a print-all macro in vm-early.l; being a form it needs
;; to be defined very early, especially on high safety/debug level.
(define-primitive-function (print-all ()) _
  (let ((stream (pop -args-)))
    (list-do arg -args-
      (do-print stream arg false))))
