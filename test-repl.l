;; (require "parser.l")
;; (require "peg-compile.l")
;; (require "peg.l")

(define-function simple-grammar (rules)
  (let ((g (grammar '<*inline*> '<parser> ())))
    (println "RULES "rules)
    (with-map grammar-add-rule g rules)
    (println "GRAMMAR "g)
    (peg-compile-grammar g)
    (new (eval '<*inline*>))))

(let* ((s (parser-stream (input-stream *input*)))
       (p (new <peg-parser>)))
  (set (<parser>-source p) s)
  (while ($sexpression p)
    (let ((exp (<parser>-result p)))
      (println exp)
      (println " => "(eval exp)))))

(define-selector twice)

(define-method twice <long> () (+ self self))

(println (twice 21))

{ start = sexpression; }
