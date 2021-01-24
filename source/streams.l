;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO this file is meant to be loadable into both the evaluator and
;; the compiled code, but it requires the handling of boxing/unboxing
;; to be merged between interpreted and compiled code.

;; (require "source/unit-test.l")
;;(define-type <stream>)
(define-record <stream> () ())

(define-selector at-end?	(stream) (error "missing method for at-end?"))
(define-selector peek		(stream) (error "missing method for peek"))
(define-selector next		(stream) (error "missing method for next"))

;;;----------------------------------------------------------------

;; TODO delete size
;; TODO WARNING this can override the one in parsing/parser.l
;; (define-record <string-stream> <stream> (string size position))

;; (define-function string-stream (str)
;;   (assert (is <string> str))
;;   (make <string-stream>
;;     (string	str)
;;     (size	(box <long> (string-length str)))
;;     (position	(box <long> 0))))

;; (define-method at-end? <string-stream> ()
;;   (= self.position self.size))

;; (define-method peek <string-stream> ()
;;   (let ((pos	(unbox <long> self.position))
;;         (size	(unbox <long> self.size)))
;;     (if (< pos size)
;;         (string-at self.string pos)
;;       +end+)))

;; (define-method next <string-stream> ()
;;   (let ((pos (unbox <long> self.position))
;;         (size	(unbox <long> self.size)))
;;     (if (< pos size)
;; 	(let ((value (string-at self.string pos)))
;; 	  (set self.position (box <long> (+ pos 1)))
;; 	  value)
;;       +end+)))

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
