;;; -*- mode: lisp; coding: us-ascii -*-

(define-function k/string-length (obj)		(get/long (get <string> size obj)))
(define-function k/array-length  (obj)		(get/long (get <array> size obj)))

(define-function k/array-at (obj idx)
  (safety 1 (or (and (is <array> obj) (<= 0 idx)) (fatal2 "k/array-at: called with object of type %d, and index %d" (get/type obj) idx)))
  (and (is <array> obj)
       (let ((elements (get <array> _bits obj))
             (size     (k/array-length obj)))
         (and (<= 0 idx)
              (< idx size)
              (oop-at elements idx)))))

(define-function k/set-array-at (obj idx val)
  (safety 1 (or (and (is <array> obj) (<= 0 idx)) (fatal2 "k/set-array-at: called with object of type %d, and index %d" (get/type obj) idx)))
  (and (is <array> obj)
       (let* ((elts (get <array> _bits obj))
              (size (k/array-length obj))
              (cap  (bytes-to-words (gc/object-size elts))))
         (and (<= 0 idx)
              (let ()
                (or (< idx cap)
                    (let ()
                      (while (not (< idx cap))
                        (set cap (* cap 2)))
                      (gc/let* ((new-elts (new-object <data> cap))) ; note: gc/protect it's not strictly necessary here, because we store it before any new allocation
                        (copy-oops elts new-elts size)
                        (set elts (put <array> _bits obj new-elts)))))
                (unless (< idx size)
                  ;; record the largest ever written index + 1 (aka size) in the size slot
                  (put <array> size obj (new-<long> (+ 1 idx))))
                (set-oop-at elts idx val))))))

(define-function k/array-append (array val)
  (k/set-array-at array (k/array-length array) val))

(define-function k/array-insert (array index value)
  (let ((len (k/array-length array)))
    (k/array-append array value)         ; ensure we have enough room
    (and (< index len)
         (let* ((elts (get <array> _bits array))
                (src (+ elts (words-to-bytes index))))
           (move-oops src
                      (+ src (words-to-bytes 1))
                      (- len index)))))
  (k/set-array-at array index value))
