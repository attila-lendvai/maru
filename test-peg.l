;; (require "parser.l")
;; (require "peg.l")

(define peg-grammar-string (input-stream-up-to (input-stream (open "peg.g")) ()))

(define peg-ir (array->list (parse-all (new <peg-parser>) (string-stream peg-grammar-string))))

(map println peg-ir)

;; (define-selector $repl)

;; (define-method $repl <peg-to-cola-parser> (source)
;;   (set self.source source)
;;   (while ($start self)
;;     (println (eval self.result))))

;; ($repl (parser-with-input <ir-to-cola-parser> (parser-with-input <peg-to-ir-parser> (input-stream *input*))))
