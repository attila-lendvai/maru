;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; A simple memory buffer with dynamic reallocation

;; TODO this should be merged with source/evaluator/buffer.l

(define-record <buffer> () (size elements capacity))

;; TODO this is only slightly different from what is in source/evaluator/array.l.
;; maybe try to merge them by eliminating the differences between the level-shifted code and normal maru code.
(define-form define-vector-accessors (type-name basename accessor copier element-size-in-bytes)
  (let ((acc-size	`(,(concat-symbol type-name '-size)	obj))
        (acc-elements	`(,(concat-symbol type-name '-elements)	obj))
        (acc-capacity	`(,(concat-symbol type-name '-capacity)	obj))
        (setter-name	(concat-symbols 'set- basename '-at))
        (getter-name	(concat-symbol basename '-at))
        (length-name	(concat-symbol basename '-length))
        (append-name	(concat-symbol basename '-append))
        (insert-name	(concat-symbol basename '-insert))
        (zeroed-name	(concat-symbol basename '-ensure-zero-terminated)))
    `(let ()
       (define-function ,length-name (obj)
         ,acc-size)

       (define-function ,getter-name (obj idx)
         (and (< idx ,acc-size)
              (,accessor ,acc-elements idx)))

       (define-function ,setter-name (obj idx val)
         (let* ((elements	,acc-elements)
                (size		,acc-size)
                (capacity	,acc-capacity))
           (unless (< idx capacity)
             (when (= 0 capacity)
               (set capacity 1))
             (while (not (< idx capacity))
               (set capacity (* capacity 2)))
             (let ((new-elements (allocate-data (* capacity ,element-size-in-bytes))))
               (,copier elements new-elements size)
               (set ,acc-elements (set elements new-elements))
               (set ,acc-capacity capacity)))
           (when (<= size idx)
             ;; record the largest ever written index + 1 (aka size) in the size slot
             (set ,acc-size (+ 1 idx)))
           (set (,accessor elements idx) val)))

       (define-function ,append-name (obj val)
         (,setter-name obj (,length-name obj) val))

       ;; (define-function ,insert-name (obj idx value)
       ;;   (let ((size (,length-name obj)))
       ;;     (,append-name obj 0)      ; ensure that we have enough room
       ;;     (when (< idx size)
       ;;       (let* ((elements	,acc-elements)
       ;;              (src	(+ elements (* idx ,element-size-in-bytes))))
       ;;         (,mover src
       ;;                 (+ src ,element-size-in-bytes)
       ;;                 (- size idx)))))
       ;;   (,setter-name obj idx value))

       (define-function ,zeroed-name (obj)
         (let ((size (,length-name obj)))
           (,setter-name obj size 0)
           (set ,acc-size size))
         obj))))

(define-vector-accessors <buffer>	buffer	byte-at		copy-bytes	1)

(define-function buffer args
  (let ((initial-capacity (if (pair? args) (first args) 32))
        (self (new <buffer>)))
    (with-instance-accessors self <buffer>
      (set self.size		0)
      (set self.elements	(allocate-data initial-capacity))
      (set self.capacity	initial-capacity)
      self)))

(define-function buffer-reset (self)
  (set (<buffer>-size self) 0))

(define-function buffer-append-string (buf str)
  (let ((i 0)
        (c 0))
    (while (set c (string-at str i))
      (buffer-append buf c)
      (incr i))))

(define-function buffer-save (self path)
  (with-instance-accessors self <buffer>
    (let ((f (or (file-open path "w")
                 (error "cannot open for writing: "path)))
          (elements self.elements))
      (for (i 0 self.size)
        ;; TODO file-write-byte?
        (file-write-character (byte-at elements i) f))
      (file-close f))))
