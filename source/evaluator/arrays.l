;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO introduce an array-kind type and turn most of this into mere functions
;; TODO audit this for the two use-cases: idx is bytes or cells
;; TODO this has no proper bounds checking. decide whether it's really a good idea to just return nil when index is out of range
(define-form define-vector-accessors (type-name basename elements-are-pointers? accessor copier mover element-size-in-bytes)
  ;; TODO this assert itself is broken, probably due to some peciuliarity of define-form/target
  ;;(assert (or (not elements-are-pointers?) (= element-size-in-bytes target/cell-size/bytes)))
  (let ((setter-name (concat-symbols 'set- basename 'at))
        (getter-name (concat-symbol basename 'at))
        (length-name (concat-symbol basename 'length))
        (append-name (concat-symbol basename 'append))
        (insert-name (concat-symbol basename 'insert))
        (ensize-name (concat-symbol basename 'ensure-size))
        (zeroed-name (concat-symbol basename 'ensure-zero-terminated)))
    `(let ()

       (define-function ,length-name (obj)
         (unbox <long> (slot-value ,type-name size obj)))

       (define-function ,getter-name (obj idx)
         (safety 2 (unless (and (is ,type-name obj) (<= 0 idx)) (fatal (string ,(symbol->string getter-name)) ": called with object of type" (type-of obj) ", index " idx)))
         (let ((elements (slot-value ,type-name elements obj))
               (size     (,length-name obj)))
           (and (< idx size)
                (,accessor elements idx))))

       (define-function ,ensize-name (obj needed-size)
         (safety 2 (or (is ,type-name obj) (fatal (string ,(symbol->string ensize-name)) ": called with object of type " (type-of obj) ", needed-size " needed-size)))
         (let* ((needed-capacity (* needed-size ,element-size-in-bytes))
                (elements	(slot-value ,type-name elements obj))
                (size		(,length-name obj))
                (capacity	(if elements
                                    (/ (gc/object-size elements)
                                       ,element-size-in-bytes)
                                  0)))
           (unless (<= needed-capacity capacity)
             (when (zero? capacity)
               (set capacity 4)) ; start from a reasonably not-small number
             (until (<= needed-capacity capacity)
               (set capacity (* capacity 2)))
             (gc/let* ((new-elements (,@(if elements-are-pointers? '(allocate <data>) '(allocate-data))
                                      (* capacity ,element-size-in-bytes)))) ; note: gc/protect is not strictly necessary here, because we store it before any new allocation
               (,copier elements new-elements size)
               (set elements (set (slot-value ,type-name elements obj) new-elements))))
           (when (<= size needed-size)
             ;; we are growing it beyond the current size
             (set (slot-value ,type-name size obj) (box <long> needed-size)))
           obj))

       (define-function ,setter-name (obj idx val)
         (safety 2 (or (and (is ,type-name obj) (<= 0 idx)) (fatal (string ,(symbol->string setter-name)) ": called with object of type " (type-of obj) ", index " idx)))
         (,ensize-name obj (+ idx 1))  ; ensure space for it
         (set (,accessor (slot-value ,type-name elements obj) idx) val))

       (define-function ,append-name (obj val)
         (,setter-name obj (,length-name obj) val))

       (define-function ,insert-name (obj idx value)
         (safety 2 (or (and (is ,type-name obj) (<= 0 idx)) (fatal (string ,(symbol->string insert-name)) ": called with object of type " (type-of obj) ", index " idx)))
         (let ((size (,length-name obj)))
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
         (safety 2 (or (is ,type-name obj) (fatal (string ,(symbol->string zeroed-name)) ": called with object of type " (type-of obj))))
         (if (gc/read-only-object? obj)
             (safety 3 (or (and (is ,type-name obj) (not (,getter-name obj (,length-name obj)))) (fatal (string ,(symbol->string zeroed-name)) ": an ensure-zero-terminated function was called on a read-only object that is not zero terminated")))
           (let ((size (,length-name obj)))
             (,setter-name obj size 0)
             ;; reset back the length
             (set (slot-value ,type-name size obj) (box <long> size))))
         obj))))

(define-vector-accessors <array>	array-		true	oop-at		copy-oops	platform/move-oops	target/cell-size/bytes)
(define-vector-accessors <string>	string-		()	u8-at		copy-bytes	platform/move-bytes	1)

(when-at-expand (feature memory-block)
  ;; FIXME: if these two when-at-expand's are merged, then a set form
  ;; transform (expand/encode/etc) happens differently and it fails to
  ;; load.
  (define-vector-accessors <memory-block>	memory-block/	()	u8-at		copy-bytes	platform/move-bytes	1))

(when-at-expand (feature memory-block)

;; TODO decide where the DEFINE-VM-FUNCTION should be and make it uniform
(define-vm-function memory-block ((capacity <long> 0))
  (make <memory-block>
    (size	(box <long> 0))
    (elements	(when (> capacity 0)
                  (allocate-data capacity)))))

(define-vm-function memory-block->lower/function ((array <memory-block>))
  (make <target-function>
    (program-code	(slot-value <memory-block> elements array))))

(define-vm-function (memory-block/length ()) ((array <memory-block>))
  (box <long> (memory-block/length array)))

;; memory-block accessors are byte indexed
;; TODO memory-block/at should be called u8-at, but the macrology above doesn't allow
(define-vm-function (u8-at ()) ((array <memory-block>) (byteindex <long>))
  (box <long> (memory-block/at array byteindex)))

(define-vm-function (set-u8-at ()) ((array <memory-block>) (byteindex <long>) (value <long>))
  ;; TODO? add error reporting for out of range values
  (set (memory-block/at array byteindex) value)
  (box <long> value))

(define-vm-function (u32-at ()) ((array <memory-block>) (byteindex <long>))
  (box <u32> (u32-at (<memory-block>-elements array) byteindex)))

(define-vm-function (set-u32-at ()) ((array <memory-block>) (byteindex <long>) value)
  (memory-block/ensure-size array (+ byteindex 4))
  (typecase value
    (<long>
     ;; TODO? add error reporting for out of range values
     (set (u32-at (<memory-block>-elements array) byteindex) (unbox <long> value)))
    (<u32>
     (set (u32-at (<memory-block>-elements array) byteindex) (unbox <u32> value)))
    (else
     (error "set-u32-at: don't know how to handle value: "value)))
  value)

(when-at-expand (= 64 target/cell-size/bits)

(define-vm-function (u64-at ()) ((array <memory-block>) (byteindex <long>))
  (box <u64> (u64-at (<memory-block>-elements array) byteindex)))

(define-vm-function (set-u64-at ()) ((array <memory-block>) (byteindex <long>) value)
  (memory-block/ensure-size array (+ byteindex 8))
  (typecase value
    (<long>
     ;; TODO? add error reporting for out of range values
     (set (u64-at (<memory-block>-elements array) byteindex) (unbox <long> value)))
    (<u64>
     (set (u64-at (<memory-block>-elements array) byteindex) (unbox <u64> value)))
    (else
     (error "set-u64-at: don't know how to handle value: "value)))
  value)

) ; (= 64 target/cell-size/bits)

(define-function memory-block/ensure-size/cell (array cell-index)
  (memory-block/ensure-size array (* (+ cell-index 1) target/cell-size/bytes)))

(define-function to-C-strings (obj offset)
  (let ((lower-array (memory-block 4))
        (i offset))
    (typecase obj
      (<undefined>) ; empty list
      (<array>
       (let ((limit (+ 1 (array-length obj))))
         (while (< i limit)
           (memory-block/ensure-size/cell lower-array i)
           ;; NOTE: we can't cache the elements slot, because it's
           ;; changing when the array grows.
           (set (oop-at (<memory-block>-elements lower-array) i)
                (string->C-string (array-at obj i)))
           (incr i))))
      (<pair>
       (while (pair? obj)
         (memory-block/ensure-size/cell lower-array i)
         (set (oop-at (<memory-block>-elements lower-array) i)
              (string->C-string (pop obj)))
         (incr i)))
      (else (error "to-C-strings: cannot handle passed obj of type "(type-of obj))))
    lower-array))

) ; (feature memory-block)

(define-vm-function string-insert-all ((str <string>) (idx <long>) (insertion <string>))
  (string-do char insertion
    (string-insert str idx char)
    (incr idx))
  str)

(define-function string-append-all (str val)
  (string-insert-all str (string-length str) val))

;; KLUDGE a quick hack to proceed with build.l
(define-vm-function set-string-length ((obj <string>) (len <long>))
  (set (slot-value <string> size obj)
       (box <long> len)))

;; WARNING libc's strcmp, and maybe even memcmp, are not necessarily reliable for
;; sorting strings. see: https://stackoverflow.com/questions/36518931/what-does-strcmp-return-if-two-similar-strings-are-of-different-lengths

(define-function string-compare (str-a str-b)
  (safety 2 (or (and (is <string> str-a) (is <string> str-b)) (fatal "string-compare: called with non-string")))
  (let* ((len-a	(string-length str-a))
         (len-b	(string-length str-b))
         (buf-a	(<string>-elements str-a))
         (buf-b	(<string>-elements str-b))
         (limit	(min len-a len-b))
         (diff	0)
         (i	0))
    (while (and (< i limit)
                (= 0 (set diff (- (u8-at buf-a i)
                                  (u8-at buf-b i)))))
      (incr i))
    (cond
      ((or (not (= 0 diff))
           (= len-a len-b))
       diff)
      ((< len-a len-b)
       (- 0 (u8-at buf-b len-a)))
      (else ;; (> len-a len-b)
       (- (u8-at buf-a len-b) 0)))))

;; we need this because in the target `=` is compiled to a dumb
;; non-dispatching integer comparison. if we want to share the
;; codebase between the kernel and the vm, then we probably need to
;; retain a separate string=. alternatively, we could smarten up the
;; way `=` is compiled, but that would slow down every comparison.
(define-function string= (a b)
  (= 0 (string-compare a b)))

;; NOTE there's a variant of this in sequences.l, but it's not trivial to merge them.
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
