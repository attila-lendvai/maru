;;; -*- mode: lisp; coding: us-ascii -*-
(require "source/files.l")
(require "image/manifest.l")

(define-function image-write (stream text)
  (for (i 0 (string-length text))
    (file-write-byte-or-die (string-at text i) stream)))

(define-function image-quote (stream text)
  (file-write-byte-or-die ?\" stream)
  (for (i 0 (string-length text))
    (let ((c (string-at text i)))
      (if (or (= c ?\") (= c ?\\))
          (file-write-byte-or-die ?\\ stream))
      (file-write-byte-or-die c stream)))
  (file-write-byte-or-die ?\" stream))

(define-function image-marker? (text pos marker)
  (let ((same true) (n (string-length marker)))
    (if (> (+ pos n) (string-length text)) false
      (begin
        (for (j 0 n)
          (if (!= (string-at text (+ pos j)) (string-at marker j))
              (set same false)))
        same))))

(define-function image-table (stream)
  (image-write stream "(define-function embedded-source (path)\n  (cond\n")
  (list-do path *image-files*
    (image-write stream "    ((embedded-path=? path ")
    (image-quote stream path)
    (image-write stream ") ")
    (image-quote stream (image-source path))
    (image-write stream ")\n"))
  (image-write stream "    (else 0)))\n"))

(let ((template (image-source "image/vm-template.l"))
      (marker "@@TABLE@@")
      (out (file-open-or-die "candidate-vm.l" "w"))
      (i 0))
  (while (< i (string-length template))
    (if (image-marker? template i marker)
        (begin (image-table out) (set i (+ i (string-length marker))))
      (begin (file-write-byte-or-die (string-at template i) out)
             (set i (+ i 1)))))
  (file-close-or-die out))
(println "Generated candidate-vm.l from embedded sources using Maru")
