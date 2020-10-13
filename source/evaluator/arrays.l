;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO this is only slightly different from what is in source/arrays.l.
;; maybe try to merge them by eliminating the differences between the level-shifted code and normal maru code.
(define-form define-vector-accessors (type-name basename elements-are-opaque? accessor copier mover element-size-in-bytes)
  (let ((setter-name (concat-symbols 'set- basename 'at))
        (getter-name (concat-symbol basename 'at))
        (length-name (concat-symbol basename 'length))
        (append-name (concat-symbol basename 'append))
        (insert-name (concat-symbol basename 'insert))
        (zeroed-name (concat-symbol basename 'ensure-zero-terminated)))
    `(let ()
       (define-function ,length-name (obj)
         (get/long (get (,type-name size) obj)))

       (define-function ,getter-name (obj idx)
         (safety 1 (or (and (is ,type-name obj) (<= 0 idx)) (fatal2 ,(concat-string (symbol->string getter-name) ": called with object of type %ld, and index %ld") (type-of obj) idx)))
         (let ((elements (get (,type-name elements) obj))
               (size     (,length-name obj)))
           (and (< idx size)
                (,accessor elements idx))))

       (define-function ,setter-name (obj idx val)
         (safety 1 (or (and (is ,type-name obj) (<= 0 idx)) (fatal2 ,(concat-string (symbol->string setter-name) ": called with object of type %ld, and index %ld") (type-of obj) idx)))
         (let* ((elements	(get (,type-name elements) obj))
                (size		(get/long (get (,type-name size) obj)))
                (capacity	(if elements
                                    (/ (gc/object-size elements)
                                       ,element-size-in-bytes)
                                  0)))
           (unless (< idx capacity)
             (when (= 0 capacity)
               (set capacity 4)) ; start from a reasonably not-small number
             (while (not (< idx capacity))
               (set capacity (* capacity 2)))
             (gc/let* ((new-elements (,(if elements-are-opaque? 'gc/allocate-opaque 'gc/allocate)
                                       <data> (* capacity ,element-size-in-bytes)))) ; note: gc/protect is not strictly necessary here, because we store it before any new allocation
               (,copier elements new-elements size)
               (set elements (put (,type-name elements) obj new-elements))))
           (when (<= size idx)
             ;; record the largest ever written index + 1 (aka size) in the size slot
             (put (,type-name size) obj (new-<long> (+ 1 idx))))
           (set (,accessor elements idx) val)))

       (define-function ,append-name (obj val)
         (,setter-name obj (,length-name obj) val))

       (define-function ,insert-name (obj idx value)
         (let ((size (,length-name obj)))
           (,append-name obj 0) ; ensure that we have enough room
           (when (< idx size)
             (let* ((elements	(get (,type-name elements) obj))
                    (src	(+ elements (* idx ,element-size-in-bytes))))
               (,mover src
                       (+ src ,element-size-in-bytes)
                       (- size idx)))))
         (,setter-name obj idx value))

       (define-function ,zeroed-name (obj)
         (let ((size (,length-name obj)))
           (,setter-name obj size 0)
           (put (,type-name size) obj (new-<long> size)))
         obj))))

(define-vector-accessors <array>	array-		()	oop-at		copy-oops	move-oops	+word-size-in-bytes+)
(define-vector-accessors <string>	string-		true	byte-at		copy-bytes	move-bytes	1)

(define-function array-binary-search (array item comparator inserter)
  (let ((lo 0)
        (hi (- (array-length array) 1)))
    (while (<= lo hi)
      (let* ((mid	(/ (+ lo hi) 2))
             (candidate	(array-at array mid))
             (res	(comparator item candidate)))
        (cond
          ((< res 0)	(set hi (- mid 1)))
          ((> res 0)	(set lo (+ mid 1)))
          (else		(return candidate)))))
    (if inserter
        (inserter array lo item)
      ())))
