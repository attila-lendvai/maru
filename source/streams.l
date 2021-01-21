;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/unit-test.l")

;(define-type <stream>)
(define-record <stream> () ())

;; (eval-in-slave `(println "in target: " ,<stream>))
;; (eval-in-slave `(println "in slave: " <stream>))

(define-selector at-end?	(stream) (error "missing method for at-end?"))
(define-selector peek		(stream) (error "missing method for peek"))
(define-selector next		(stream) (error "missing method for next"))

;;;----------------------------------------------------------------

(define-record <string-stream> <stream> (string size position))

(define-function string-stream (str)
  (make <string-stream>
    (string	str)
    (size	(string-length str))
    (position	0)))

(define-method at-end? <string-stream> ()
  (= self.position self.size))

(define-method peek <string-stream> ()
  (if (< self.position self.size)
      (string-at self.string self.position)
    +end+))

(define-method next <string-stream> ()
  (let ((pos self.position))
    (if (< pos self.size)
	(let ((value (string-at self.string pos)))
	  (set self.position (+ pos 1))
	  value)
      +end+)))

;; (unit-test "<string-stream>"
;;   (let ((s (string-stream "xhello"))
;; 	(c 0)
;; 	(a (array)))					(unit-assert (= ?x (peek s)))
;; 							(unit-assert (= ?x (next s)))
;; 							(unit-assert (= ?h (peek s)))
;;     (while (!= +end+ (set c (next s)))
;;       (array-append a c))				(unit-assert (= "hello" (array->string a)))
;; 							(unit-assert (= +end+ (peek s)))
;; 							(unit-assert (= +end+ (next s)))))

;; (define-method $source-position <undefined> ())
;;
;; (define-method $source-position <string-stream> ()
;;   (cons "<string>" self.position))
