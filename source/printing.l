;;; -*- mode: lisp; coding: us-ascii -*-

(define-selector do-print (self stream)
  (print-all stream "["(type-name-of self)" "(type-id-of self)"]"))

(define-selector do-dump (self stream)
  (dump-all stream self))

(define-form define-print-method (type . body)
  `(define-method do-print ,type (-stream-)
     ,@body))

(define-function print-all (stream . args)
  (while (pair? args)
    (do-print (pop args) stream)))

(define-function dump-all (stream . args)
  (while (pair? args)
    (do-dump (pop args) stream)))

(define-function print args
  (let ((l args))
    (while (pair? l)
      (do-print (pop l) *standard-output*)))
  (car args))

(define-function dump args
  (let ((l args))
    (while (pair? l)
      (do-dump (pop l) *standard-output*))
    (car args)))

(define-function println args
  (apply print-all (cons *standard-output* args))
  (print-all *standard-output* "\n")
  (car args))

(define-function dumpln args
  (apply dump-all (cons *standard-output* args))
  (print-all *standard-output* "\n")
  (car args))

(define-function %print-list (stream lst storing?)
  (primitive/print-all stream "(")
  (let ((first-time?	true)
        (cell		lst))
    (while (pair? cell)
      (if first-time?
          (set first-time? ())
        (primitive/print-all stream " "))
      ((if storing? do-dump do-print) (car cell) stream)
      (set cell (cdr cell)))
    (when cell
      (print-all stream " . " cell))
    (primitive/print-all stream ")")))

(with-forms ((redirect (types `(let ()
                                 ,@(map (lambda (type)
                                          `(define-print-method ,type
                                             (primitive/print-all -stream- self)))
                                        types)))))
  ;; by default redirect the printing of these types to the do-print primfn of the evaluator.
  (redirect <undefined> <string> <symbol> <long> <array> <variable> <primitive-function>))

(with-forms ((redirect (types `(let ()
                                 ,@(map (lambda (type)
                                          `(define-method do-dump ,type (stream)
                                             (primitive/dump-all stream self)))
                                        types)))))
  ;; by default redirect the dumping of these types to the do-print primfn of the evaluator.
  (redirect <undefined> <string> <symbol> <long> <array>))

(define-print-method <fixed>	(print-all -stream- "<fixed "self.function">"))
(define-print-method <selector>	(print-all -stream- "<selector "self.name">"))
(define-print-method <expr>	(print-all -stream- "<expr "(or (when-at-expand feature/track-expr-names self.name) "?")" "self.parameters">"))
(define-print-method <env>	(print-all -stream- "<env Lv"self.level",Off"self.offset",#"(array-length self.bindings)">"))
(define-print-method <module>	(print-all -stream- "<module "(or (when-at-expand feature/debug-info self.name) "?") ">"))
(define-print-method <type>	(print-all -stream- "<"(<type>-name self)" "(<type>-id self)">"))
(define-print-method <pair>	(%print-list -stream- self false))

(define-method do-dump <pair> (stream)
  (%print-list stream self true))

(define-print-method <array>
  (primitive/print-all -stream- "Array(")
  (for (i 0 (array-length self))
    (when (< 0 i)
      (primitive/print-all -stream- " "))
    (do-print (array-at self i) -stream-))
  (primitive/print-all -stream- ")"))

;; (define-function dump-until (target arg)
;;   (let ((found (= target arg)))
;;     (if (pair? arg)
;;         (let ()
;;           (print "(")
;;           (while arg
;;             (if (pair? arg)
;;                 (if (dump-until target (car arg))
;;                     (let ()
;;                       (if (cdr arg) (print " ..."))
;;                       (set found true)
;;                       (set arg ())))
;;               (let ()
;;                 (print ". ")
;;                 (dump-until target arg)))
;;             (if (set arg (cdr arg))
;;                 (print " ")))
;;           (print ")"))
;;       (dump arg))
;;     found))
