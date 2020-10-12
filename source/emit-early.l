;;; -*- mode: lisp; coding: us-ascii -*-

;; NOTE for debugging only, because this breaks the output due to multiline string literals escaping the line-comment syntax
(define *compiler-verbose* '())

;; NOTE using symbols here is not a good idea because of the host/slave isolation
(define-constant target/machine (cond
                                  ((or (= target/cpu "x86_64"))		"x86-64")
                                  ((or (= target/cpu "i686")
                                       (= target/cpu "i386"))		"IA-32")
                                  (else (error "Couldn't identify target/machine from target/cpu: "target/cpu))))

(define-constant target/word-size-in-bits (cond
                                            ((= target/machine "x86-64")	64)
                                            ((= target/machine "IA-32")		32)
                                            (else (error "Couldn't identify word size from target/machine: "target/machine))))

(define *target-module* (create-module "target"))

(eval-in-module *target-module*
  `(let ()
     (define *host-module*	,(current-module))
     (define *slave-module*	,*slave-module*)
     ;;(define slave-value	,slave-value)
     ;;(define eval-in-slave	,eval-in-slave)
     (set *syntax-module*	,*slave-module*)))

;; stubs for the +special-forms+
(list-do name '(return address-of << >>)
  (eval-in-module *target-module* `(define ,name (fixed (lambda _ (print ,(symbol->string name) " encountered in interpreted code") (abort))))))

;; stubs for the +special-operators+
;; (list-do name '()
;;   ;; they need to be subr's, so that encode doesn't insert them
;;   (eval-in-module *target-module* `(define ,name error)))

(switch-to-slave-module)

(define-constant target-boolean/true  1)
(define-constant target-boolean/false 0)

(define-function target-boolean (value)
  (if value target-boolean/true target-boolean/false))

;;;
;;; the target's configuration
;;;
(define-constant target/cpu			(host-value target/cpu))
(define-constant target/machine			(host-value target/machine))
(define-constant target/vendor			(host-value target/vendor))
(define-constant target/os			(host-value target/os))
(define-constant target/word-size-in-bits	(host-value target/word-size-in-bits))
(define-constant target/little-endian?		true)
;;(define-constant target-triplet			(concat-strings target/cpu "-" target/vendor "-" target/os))

;;;
;;; useful utils and constants
;;;
(define-constant target/word-size-in-bytes	(/ target/word-size-in-bits 8))

(define-form bytes-to-words (value)
  (if (long? value)
      (/  value  target/word-size-in-bytes)
     `(/ ,value ,target/word-size-in-bytes)))

(define-form words-to-bytes (value)
  (if (long? value)
      (* value   target/word-size-in-bytes)
     `(* ,value ,target/word-size-in-bytes)))

;;;
;;; host code follows from here
;;;
(switch-to-host-module)

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

(define-function eval-in-target (form)
  (eval-in-module *target-module* form))

(define-form target-value (form)
  `(eval-in-target ',form))

;;;
;;; FFI
;;;
(define-record <foreign-function> ()
  (name
   return-type
   parameter-types
   n-params
   vararg?))

(define-method do-print <foreign-function> ()
  (print "<<foreign-function> "self.return-type", "self.name", "self.parameter-types", "self.vararg?">"))

(define-function foreign-function (return-type foreign-name parameter-types)
  (let* ((rev-types (list-reverse parameter-types))
         (vararg? (= '... (first rev-types))))
    (when vararg?
      (pop rev-types))
    (set parameter-types (list-reverse! rev-types))
    (make <foreign-function>
      (name		foreign-name)
      (return-type	return-type)
      (parameter-types	parameter-types)
      (n-params		(list-length parameter-types))
      (vararg?		vararg?))))

;;;
;;; Utils
;;;
(let ((counter 0))
  (define-function unique-name (prefix)
    (concat-string prefix (long->string (incr counter)))))

(define-function align (alignment value)
  (bitwise-and (+ value (- alignment 1))
               (- alignment)))

;; TODO this is naive, should also deal with varargs explicitly instead of just returning nil
(define-function <expr>-n-required-parameters (op)
  (let ((params		(<expr>-parameters op))
        (n-params	()))
    (cond
      ((not params))                   ; (lambda () ...)
      ((symbol? params))               ; (lambda args ...)
      ((pair? params)
       (set n-params 1)
       (while (pair? (set params (rest params)))
         (incr n-params))
       (when (symbol? params)          ; (lambda (arg1 . rest) ...)
         (set n-params ())))
      (else
       (error "<expr>-n-required-parameters: error parsing <expr> " op ", parameters " params)))
    n-params))
