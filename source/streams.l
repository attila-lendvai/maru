;;; -*- mode: lisp; coding: us-ascii -*-

;; NOTE currently the evaluator and the target stream worlds are separate

(require "source/unit-test.l")
(require "source/files.l")

(define-selector $at-end?)
(define-selector $peek)
(define-selector $next)
(define-selector $put)
(define-selector $put-all)

;;;----------------------------------------------------------------

(define-record <string-stream> () (buffer position))

(define-function string-stream (string)
  (make <string-stream>
    (buffer	string)
    (position	0)))

(define-method $at-end? <string-stream> ()
  (>= self.position (string-length self.buffer)))

(define-method $peek <string-stream> ()
  (let ((pos self.position))
    (if (< pos (string-length self.buffer))
	(string-at self.buffer pos)
      +end+)))

(define-method $next <string-stream> ()
  (let ((pos self.position))
    (if (< pos (string-length self.buffer))
	(let ((value (string-at self.buffer pos)))
	  (set self.position (+ pos 1))
	  value)
      +end+)))

(define-method $put <string-stream> (char)
  (string-insert self.buffer self.position char)
  (incr self.position)
  char)

(define-method $put-all <string-stream> (elements)
  (typecase elements
    (<string>		(string-insert-all self.buffer self.position elements)
			(incr self.position (string-length elements)))
    (else		(error "<string-stream> $put-all: unexpected elements: " elements)))
  elements)

(define-form with-output-to-string (args . body)
  (let ((var (first args)))
    `(let ((,var (string-stream "")))
       ,@body
       (<string-stream>-buffer ,var))))

(unit-test "<string-stream>"
  (let ((s (string-stream "xhello"))
	(c 0)
	(a (array)))					(unit-assert (= ?x ($peek s)))
							(unit-assert (= ?x ($next s)))
							(unit-assert (= ?h ($peek s)))
    (while (!= +end+ (set c ($next s)))
      (array-append a c))				(unit-assert (= "hello" (array->string a)))
							(unit-assert (= +end+ ($peek s)))
							(unit-assert (= +end+ ($next s)))))

(define-method $source-position <undefined> ())

(define-method $source-position <string-stream> ()
  (cons "<string>" self.position))

;;;----------------------------------------------------------------

(define-record <list-stream> () (source))

(define-function list-stream (source)
  (make <list-stream>
    (source	source)))

(define-method $at-end? <list-stream> ()
  (not self.source))

(define-method $peek <list-stream> ()
  (if self.source
      (car self.source)
    +end+))

(define-method $next <list-stream> ()
  (if self.source
      (let ((value (car self.source)))
	(set self.source (cdr self.source))
	value)
    +end+))

(unit-test "<list-stream>"
  (let ((s (list-stream '(?x ?h ?e (l (l)) () ?o)))
	(c 0)
	(a (array)))					(unit-assert (= ?x ($peek s)))
							(unit-assert (= ?x ($next s)))
							(unit-assert (= ?h ($peek s)))
    (while (!= +end+ (set c ($next s)))
      (array-append a c))				(unit-assert (equal '(?h ?e (l (l)) () ?o) (array->list a)))
							(unit-assert (= +end+ ($peek s)))
							(unit-assert (= +end+ ($next s)))))

(define-method $source-position <list-stream> () ())

;;;----------------------------------------------------------------

(define-record <input-stream> () (source pending srcpos))

(define-function input-stream (source path)
  (make <input-stream>
    (source	source)
    (srcpos	(cons path 1))))

(define-method $at-end? <input-stream> ()
  (= () ($peek self)))

(define-method $peek <input-stream> ()
  (or self.pending
      (if self.source
	  (let ((c (file-read-character self.source)))
	    (if c
		(let ()
		  (and (= ?\n c) (set self.srcpos (cons (car self.srcpos) (+ 1 (cdr self.srcpos)))))
		  (set self.pending c))
	      (set self.source ())
	      (set self.pending +end+)))
	(set self.pending +end+))))

(define-method $next <input-stream> ()
  (let ((c ($peek self)))
    (set (<input-stream>-pending self) ())
    c))

(define-method $source-position <input-stream> ()
  self.srcpos)

(define-function input-stream-up-to (self delimiter)
  (let ((res (string)))
    (until (= delimiter ($peek self))
      (string-append res ($next self)))
    res))

(define-function contents-of-file-named (name)
  (input-stream-up-to (input-stream (or (file-open name "r")
					(error "no such file: "name))
				    name)
                      +end+))

;; (unit-test "<input-stream>"
;;   (let ((s (input-stream *input*))
;; 	(c 0)
;; 	(a (array)))						(unit-assert (= ?; ($peek s)))
;; 								(unit-assert (= ?; ($next s)))
;; 								(unit-assert (= ?h ($peek s)))
;;     (while (!= ?! (set c ($next s)))
;;       (array-append a c))					(unit-assert (= "hello" (array->string a)))
;; 								(unit-assert (= "goodbye" (input-stream-up-to s ?!)))));hello!goodbye!
