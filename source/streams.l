;;; -*- mode: lisp; coding: us-ascii -*-

;; NOTE currently the evaluator and the target stream worlds are separate

;; FIXME decide on how to handle EOF and make it uniform

(require "source/unit-test.l")
(require "source/files.l")
(require "source/streams-min.l")
(require "source/streams-min-late.l")

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

(define-record <file-input-stream> () (file pending srcpos))

(define-function file-input-stream (file path)
  (make <file-input-stream>
    (file	file)
    (srcpos	(cons path 1))))

(define-method $at-end? <file-input-stream> ()
  (= +end+ ($peek self)))

(define-method $peek <file-input-stream> ()
  (or self.pending
      (if self.file
	  (let ((c (file-read-byte self.file)))
	    (if c
		(let ()
		  (when (= ?\n c)
                    (set self.srcpos (cons (car self.srcpos)
                                           (+ 1 (cdr self.srcpos)))))
		  (set self.pending c))
	      (set self.file ()) ; TODO err...?
	      (set self.pending +end+)))
	(set self.pending +end+))))

(define-method $next <file-input-stream> ()
  (let ((c ($peek self)))
    (set self.pending ())
    c))

(define-method $source-position <file-input-stream> ()
  self.srcpos)

(define-function input-stream-up-to (stream delimiter)
  (let ((res (string))
        (char ()))
    (until (let ()
             (set char ($peek stream))
             (or (= char delimiter)
                 (= char +end+)))
      (string-append res ($next stream)))
    (if (= char delimiter)
        res
      ;; char is +end+
      (if (= 0 (string-length res))
          +end+
        res))))

(define-function contents-of-file-named (name)
  (input-stream-up-to (file-input-stream (file-open-or-die name "r")
                                         name)
                      +end+))

;;;
;;; LoC counting
;;;
(define-function maru-comment-line? (str)
  (let ((i 0)
        (end (string-length str))
        (whitespace? true))
    (while (and (< i end)
                whitespace?)
      (unless (member? (string-at str i) '(?\n ?\r ?  ?\t))
        (set whitespace? false))
      (incr i))
    (or whitespace?
        (= (string-at str i) ?\; ))))

(define-function count-maru-loc (path)
  (let* ((file (file-open-or-die path "r"))
         (stream (file-input-stream file path)))
    (let ((loc 0)
          (line ()))
      (while (not (= +end+ (set line (input-stream-up-to stream ?\n))))
        ($next stream) ; drop the \n
        (unless (maru-comment-line? line)
          (incr loc)))
      (file-close file)
      loc)))

;; (unit-test "<input-stream>"
;;   (let ((s (input-stream *input*))
;; 	(c 0)
;; 	(a (array)))						(unit-assert (= ?; ($peek s)))
;; 								(unit-assert (= ?; ($next s)))
;; 								(unit-assert (= ?h ($peek s)))
;;     (while (!= ?! (set c ($next s)))
;;       (array-append a c))					(unit-assert (= "hello" (array->string a)))
;; 								(unit-assert (= "goodbye" (input-stream-up-to s ?!)))));hello!goodbye!
