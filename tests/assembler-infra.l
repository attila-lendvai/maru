;;; -*- mode: lisp; coding: us-ascii -*-

;;; Shared infrastructure for assembler tests.
;;; Used by test-assembler-x86.l and test-assembler-aarch64.l.

(require "tests/infra.l")

(define-function string-trim-end (str)
  (let ((end (string-length str)))
    (while (begin
             (decr end)
             (member? (string-at str end) '(?\n ?\r ?  ?\t))))
    (set (string-length str) (+ end 1)))
  str)

(define-function run-capture (path argv)
  (string-trim-end (run-program path argv () () 'string)))

(define-function run-shell (cmd)
  (run-capture "/usr/bin/env" (list "sh" "-c" cmd)))

(define-function write-file (path contents)
  (let ((fd (file-open-or-die path "w")))
    (let ((idx 0)
          (len (string-length contents)))
      (while (< idx len)
        (file-write-byte-or-die (string-at contents idx) fd)
        (incr idx)))
    (file-close-or-die fd)))

(define-function generate-reference/x86 (asm-source ref-bin)
  (let ((src-file (concat-string ref-bin ".s"))
        (obj-file (concat-string ref-bin ".o")))
    (write-file src-file asm-source)
    (run-shell (concat-strings "clang -c -o " obj-file " " src-file))
    (run-shell (concat-strings "objcopy -j .text -O binary " obj-file " " ref-bin))))

(define-function verify-encoding/x86 (filename asm-source)
  (let ((bin-filename (concat-string "build/asm-x86/" filename)))
    (save-current-segment-to-file bin-filename)
    (let ((ref-filename (concat-string bin-filename ".ref")))
      (generate-reference/x86 asm-source ref-filename)
      (let ((result (run-shell (concat-strings "cmp -s " bin-filename " " ref-filename " && echo match || echo mismatch"))))
        (test-assert (= result "match")
                     "binary mismatch for " bin-filename)))))

(define-function generate-reference/arm (asm-source ref-bin)
  (let ((src-file (concat-string ref-bin ".s"))
        (obj-file (concat-string ref-bin ".o")))
    (write-file src-file asm-source)
    (run-shell (concat-strings "clang -target aarch64 -c -o " obj-file " " src-file))
    (run-shell (concat-strings "aarch64-linux-gnu-objcopy -j .text -O binary " obj-file " " ref-bin))))

(define-function verify-encoding/arm (filename asm-source)
  (let ((bin-filename (concat-string "build/asm-arm/" filename)))
    (save-current-segment-to-file bin-filename)
    (let ((ref-filename (concat-string bin-filename ".ref")))
      (generate-reference/arm asm-source ref-filename)
      (let ((result (run-shell (concat-strings "cmp -s " bin-filename " " ref-filename " && echo match || echo mismatch"))))
        (test-assert (= result "match")
                     "binary mismatch for " bin-filename)))))
