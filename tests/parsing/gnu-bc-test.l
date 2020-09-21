(require "source/parsing/parser.l")
(require "tests/parsing/gnu-bc.g.l")

;; TODO this should actually assert once we have read-from-string

(define *test-expr* "3 + 4
100 * 9 / 5 + 32")

(println "\nall three outputs should print 7 and 212:\n")

(peg-disable-memoisation)
(map dumpln (parse-string <bc> $program *test-expr*))

(peg-enable-memoisation)
(map dumpln (parse-string <bc> $program *test-expr*))

(peg-enable-recursion)
(map dumpln (parse-string <bc> $program *test-expr*))
