;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO this is only slightly different from what is in source/arrays.l.
;; maybe try to merge them by eliminating the differences between the level-shifted code and normal maru code.
;; TODO this has no proper bounds checking. decide whether it's really a good idea to just return nil when index is out of range
(define-form define-vector-accessors (type-name basename elements-are-pointers? accessor copier mover element-size-in-bytes)
  ;; TODO this assert itself is broken, probably due to some peciuliarity of define-form/target
  ;;(assert (or (not elements-are-pointers?) (= element-size-in-bytes +word-size-in-bytes+)))
  (let ((setter-name (concat-symbols 'set- basename 'at))
        (getter-name (concat-symbol basename 'at))
        (length-name (concat-symbol basename 'length))
        (append-name (concat-symbol basename 'append))
        (insert-name (concat-symbol basename 'insert))
        (zeroed-name (concat-symbol basename 'ensure-zero-terminated)))
    ;; TODO fix nested quasiquotes
    `(with-forms ((get-size ((obj) (list 'unbox '<long> (list 'slot-value ',type-name 'size obj)))))

       (define-function ,length-name (obj)
         (get-size obj))

       (define-function ,getter-name (obj idx)
         (safety 2 (or (and (is ,type-name obj) (<= 0 idx)) (fatal2 ,(concat-string (symbol->string getter-name) ": called with object of type %ld, and index %ld") (type-of obj) idx)))
         (let ((elements (slot-value ,type-name elements obj))
               (size     (get-size obj)))
           (and (< idx size)
                (,accessor elements idx))))

       (define-function ,setter-name (obj idx val)
         (safety 2 (or (and (is ,type-name obj) (<= 0 idx)) (fatal2 ,(concat-string (symbol->string setter-name) ": called with object of type %ld, and index %ld") (type-of obj) idx)))
         (let* ((elements	(slot-value ,type-name elements obj))
                (size		(get-size obj))
                (capacity	(if elements
                                    (/ (gc/object-size elements)
                                       ,element-size-in-bytes)
                                  0)))
           (unless (< idx capacity)
             (when (= 0 capacity)
               (set capacity 4)) ; start from a reasonably not-small number
             (while (not (< idx capacity))
               (set capacity (* capacity 2)))
             (gc/let* ((new-elements (,@(if elements-are-pointers? '(allocate <data>) '(allocate-data))
                                        (* capacity ,element-size-in-bytes)))) ; note: gc/protect is not strictly necessary here, because we store it before any new allocation
               (,copier elements new-elements size)
               (set elements (set (slot-value ,type-name elements obj) new-elements))))
           (when (<= size idx)
             ;; record the largest ever written index + 1 (aka size) in the size slot
             (set (slot-value ,type-name size obj) (box <long> (+ 1 idx))))
           (set (,accessor elements idx) val)))

       (define-function ,append-name (obj val)
         (,setter-name obj (get-size obj) val))

       (define-function ,insert-name (obj idx value)
         (safety 2 (or (and (is ,type-name obj) (<= 0 idx)) (fatal2 ,(concat-string (symbol->string insert-name) ": called with object of type %ld, and index %ld") (type-of obj) idx)))
         (let ((size (get-size obj)))
           (when (< idx size)
             ;; TODO how about insering far out into the new territory?
             (,append-name obj 0)    ; ensure that we have enough room, and that the size slot gets updated
             (when (< idx size)
               (let* ((elements	(slot-value ,type-name elements obj))
                      (src	(+ elements (* idx ,element-size-in-bytes)))
                      (dest	(+ src ,element-size-in-bytes)))
                 (,mover src dest (- size idx))))))
         (,setter-name obj idx value))

       (define-function ,zeroed-name (obj)
         (if (gc/read-only-object? obj)
             (safety 3 (or (and (is <string> obj) (not (,getter-name obj (get-size obj)))) (fatal1 ,(concat-string (symbol->string zeroed-name) "an ensure-zero-terminated function was called on a read-only object that is not zero terminated: %p") obj)))
           (let ((size (get-size obj)))
             (,setter-name obj size 0)
             (set (slot-value ,type-name size obj) (box <long> size))))
         obj))))

(define-vector-accessors <array>	array-		true	oop-at		copy-oops	platform/move-oops	+word-size-in-bytes+)
(define-vector-accessors <string>	string-		()	byte-at		copy-bytes	platform/move-bytes	1)

;; WARNING libc's strcmp, and maybe even memcmp, are not necessarily reliable for
;; sorting strings. see: https://stackoverflow.com/questions/36518931/what-does-strcmp-return-if-two-similar-strings-are-of-different-lengths

(define-function compare-strings (str-a str-b)
  (safety 2 (or (and (is <string> str-a) (is <string> str-b)) (fatal "compare-strings: called with non-string")))
  (let* ((len-a	(string-length str-a))
         (len-b	(string-length str-b))
         (buf-a	(<string>-elements str-a))
         (buf-b	(<string>-elements str-b))
         (limit	(min len-a len-b))
         (diff	0)
         (i	0))
    (while (and (< i limit)
                (= 0 (set diff (- (byte-at buf-a i)
                                  (byte-at buf-b i)))))
      (incr i))
    (cond
      ((or (not (= 0 diff))
           (= len-a len-b))
       diff)
      ((< len-a len-b)
       (- 0 (byte-at buf-b len-a)))
      (else ;; (> len-a len-b)
       (- (byte-at buf-a len-b) 0)))))

;; TODO how does this relate to the = primitive-function? maybe delme?
(define-function string= (a b)
  (= 0 (compare-strings a b)))

;; NOTE there's a variant of this in parser.l
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
