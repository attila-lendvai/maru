;;; -*- mode: lisp; coding: us-ascii -*-

;; (define-function string-reverse! (str)
;;   (let* ((len	(string-length str))
;;          (limit	(- len 1))
;;          tmp)
;;     (for (i 0 (/ len 2))
;;       (set tmp (char-at str i))
;;       (set (char-at str i) (char-at str (- limit i)))
;;       (set (char-at str (- limit i)) tmp)))
;;   str)

;; TODO empty files are not tolerated
42
