;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; A host-side arena for the target's heap.
;;;
;;; The arena is one host <memory-block> addressed by logical byte
;;; offsets. It backs a second heap env in which the target's gc.l and
;;; constructors run against the arena through shims.
;;;
;;; Only cell *contents* are target values; addresses and cell indices
;;; are host numbers. The buffer is written with target words so that
;;; the emitted heap matches the layout of the next stage's heap.
;;;
;;; Readers are erroring stubs for now: no arena GC runs during the
;;; bootstrap. Collection starts at runtime, in a later phase.

;;;
;;; configuration
;;;

(define +arena-capacity+   (* 1024 1024))
(define +arena-heap-start+ 4096)

(define arena/target-64-bit? (= 64 (eval-in-slave 'target/cell-size/bits)))
(define arena/capacity   +arena-capacity+)
(define arena/heap-start +arena-heap-start+)
(define arena/cursor     +arena-heap-start+)
(define arena/cell-bytes (if arena/target-64-bit? 8 4))

(define arena/block (memory-block arena/capacity))

;; grow the block's logical size to its capacity, so that reads of
;; unwritten bytes return zero instead of nil
(set-u8-at arena/block (- arena/capacity 1) 0)

;;;
;;; raw byte access
;;;

(define-function arena/check-range (offset size)
  (unless (and (<= 0 offset) (<= (+ offset size) arena/capacity))
    (error "arena: access out of range: offset " offset ", size " size)))

(define-function arena/load-u8 (offset)
  (arena/check-range offset 1)
  (u8-at arena/block offset))

(define-function arena/store-u8 (offset value)
  (arena/check-range offset 1)
  (set-u8-at arena/block offset (bitwise-and value 0xff))
  value)

(define-function arena/load-u32 (offset)
  (arena/check-range offset 4)
  (bitwise-or (u8-at arena/block offset)
              (bitwise-shift (u8-at arena/block (+ offset 1)) 8)
              (bitwise-shift (u8-at arena/block (+ offset 2)) 16)
              (bitwise-shift (u8-at arena/block (+ offset 3)) 24)))

(define-function arena/store-u32 (offset value)
  (arena/check-range offset 4)
  (set-u8-at arena/block offset (bitwise-and value 0xff))
  (set-u8-at arena/block (+ offset 1) (bitwise-and (bitwise-shift value -8) 0xff))
  (set-u8-at arena/block (+ offset 2) (bitwise-and (bitwise-shift value -16) 0xff))
  (set-u8-at arena/block (+ offset 3) (bitwise-and (bitwise-shift value -24) 0xff))
  value)

;;;
;;; target cells
;;;

(define-function arena/to-host (value)
  (cond
    ((is <long> value) value)
    ((is <target-cell> value) (lower-cell->long value))
    (else
     (error "arena/to-host: unexpected value " value))))

(define-function arena/address->cell (address)
  (if arena/target-64-bit?
      (make-u64 address 0)
    (make-u32 address)))

(define-function arena/tag (value)
  (bitwise-or (bitwise-shift value 1) 1))

(define arena/type->slave-id (eval-in-slave '<type>-slave-id))

(define-function arena/acquire (size)
  (let* ((size	(bitwise-and (+ size (- arena/cell-bytes 1))
                              (- arena/cell-bytes)))
         (start	arena/cursor)
         (end	(+ start size)))
    (unless (<= end arena/capacity)
      (error "arena: out of memory: capacity " arena/capacity
             ", requested " size))
    (set arena/cursor end)
    (arena/address->cell start)))

;;;
;;; the shims
;;;

;; Host objects (type objects, forms) may reach the shims; the arena
;; buffer itself only ever sees target cells.
(define arena/host-oop-at oop-at)
(define arena/host-set-oop-at set-oop-at)

(define-function arena/write-cell (offset cell)
  (if-at-expand (= 64 lower/cell-size/bits)
      (set-u64-at arena/block offset cell)
    (set-u32-at arena/block offset cell)))

(define-function arena/set-oop-at (base index value)
  (if (is <target-cell> base)
      (let ((offset (+ (lower-cell->long base) (* index arena/cell-bytes))))
        (cond
          ;; a target <long>: store its raw tagged word
          ((is <long> value)
           (arena/write-cell offset (arena/address->cell (arena/tag value))))
          ;; a boxed target word: store the word in its payload
          ((is <target-cell> value)
           (arena/write-cell offset value))
          (else
           (error "arena/set-oop-at: not a target value: " value))))
    (arena/host-set-oop-at base index value)))

(define-function arena/oop-at (base index)
  (if (is <target-cell> base)
      (error "arena: oop-at is not implemented yet")
    (arena/host-oop-at base index)))

(define-function arena/address-of-location (name)
  (error "arena: address-of-location is not implemented yet: " name))

(define-function arena/clear-cells (base count)
  (let ((offset (arena/to-host base)))
    (let ((i 0))
      (while (< i count)
        (let ((cell (+ offset (* i arena/cell-bytes))))
          (arena/store-u32 cell 0)
          (when arena/target-64-bit?
            (arena/store-u32 (+ cell 4) 0)))
        (incr i)))))

(define-function arena/unimplemented (name)
  (error "arena: " name " is not implemented yet"))

;;;
;;; peeking, for the self-check only
;;;

(define-function arena/peek-word (offset)
  (let ((lo (arena/load-u32 offset)))
    (if arena/target-64-bit?
        (+ lo (bitwise-shift (arena/load-u32 (+ offset 4)) 32))
      lo)))

(define-function arena/peek-word-at (offset index)
  (arena/peek-word (+ offset (* index arena/cell-bytes))))

(define-function arena/peek-cell (base index)
  (arena/peek-word-at (arena/to-host base) index))

;;;
;;; the heap env
;;;

(let ((heap-env (environment *slave-env*)))
  (assert (= 0 (<env>-level heap-env)))
  (define *heap-env* heap-env))

(define-function eval-in-heap (form)
  (eval form *heap-env*))

(define-form heap-value (form)
  `(eval-in-heap ',form))

(define-function arena/header-size ()
  (eval-in-heap 'size-of-<header>))

(environment-define *heap-env* 'oop-at			arena/oop-at)
(environment-define *heap-env* 'set-oop-at		arena/set-oop-at)
(environment-define *heap-env* 'address-of-location	arena/address-of-location)
(environment-define *heap-env* 'address-of		(lambda (value) 0))
(environment-define *heap-env* 'platform/acquire-memory	arena/acquire)
(environment-define *heap-env* 'platform/clear-cells	arena/clear-cells)
(environment-define *heap-env* 'platform/move-oops
                    (lambda (from to wordcount)
                      (arena/unimplemented "platform/move-oops")))
(environment-define *heap-env* 'platform/move-bytes
                    (lambda (from to count)
                      (arena/unimplemented "platform/move-bytes")))
(environment-define *heap-env* 'copy-oops
                    (lambda (from to wordcount)
                      (arena/unimplemented "copy-oops")))
(environment-define *heap-env* 'copy-bytes
                    (lambda (from to count)
                      (arena/unimplemented "copy-bytes")))
(environment-define *heap-env* 'arena/acquire		arena/acquire)
(environment-define *heap-env* 'arena/set-oop-at	arena/set-oop-at)
(environment-define *heap-env* 'arena/header-size	arena/header-size)

(define-function arena/load-target-file (path)
  (let ((prev *globals*))
    (set *globals* *heap-env*)
    (load path)
    (set *globals* prev)))

;;; A debug/fatal shim, so the target sources need no platform layer.

(define arena/noop-form
  (form (lambda (*env* . args) ())))

(environment-define *heap-env* 'debug		arena/noop-form)
(environment-define *heap-env* 'debug/identities	arena/noop-form)
(environment-define *heap-env* 'gc/debug	arena/noop-form)
(environment-define *heap-env* 'debug-print	arena/noop-form)
(environment-define *heap-env* 'fatal
                    (lambda args (error "arena fatal: " args)))
(environment-define *heap-env* 'pointer (lambda (value) value))

;;; The header layout, gc/let*, and the flags come from gc.l. Its
;;; reader and allocator paths are not executed here.

(arena/load-target-file "source/evaluator/gc.l")
(environment-define *heap-env* 'gc/push-root (lambda (ptr) ()))
(environment-define *heap-env* 'gc/pop-root  (lambda (ptr) ()))

(arena/load-target-file "source/evaluator/types.l")

;; the form machinery calls TYPE-OF on host objects; evaluator/types.l
;; defines a TYPE-OF that reads arena headers. restore the host's.
(define arena/host-type-of type-of)
(environment-define *heap-env* 'type-of arena/host-type-of)

;;;
;;; allocation on the bump arena
;;;

(define-function arena/heap-define (form)
  (let ((prev *globals*))
    (set *globals* *heap-env*)
    (eval form)
    (set *globals* prev)))

(arena/heap-define
 '(define-function arena/alloc-object (type-id byte-size flags)
    (let* ((size (oop/align byte-size))
           (header (arena/acquire (+ size (arena/header-size)))))
      (arena/set-oop-at header 0 header)
      (arena/set-oop-at header 1 size)
      (arena/set-oop-at header 2 flags)
      (arena/set-oop-at header 3 type-id)
      (gc/payload-of header))))

(arena/heap-define
 '(define-function allocate-object (type-id slot-count)
    (arena/alloc-object type-id (words-to-bytes slot-count) <header>-flags/used)))

(arena/heap-define
 '(define-function allocate-bytes (byte-size)
    (arena/alloc-object (<type>-slave-id <data>) byte-size
                        (bitwise-or <header>-flags/used <header>-flags/opaque))))

(arena/heap-define
 '(define-function allocate-oop-vector (cell-count)
    (arena/alloc-object (<type>-slave-id <oop-vector>)
                        (words-to-bytes cell-count)
                        <header>-flags/used)))

;;;
;;; constructors
;;;

(arena/heap-define
 '(define-function cons (head tail)
    (make <pair>
      (head head)
      (tail tail))))

(arena/heap-define
 '(define-function string (capacity)
    (make <string>
      (size	0)
      (elements	(when (< 0 capacity)
                  (allocate-bytes capacity))))))

(arena/heap-define
 '(define-function array (capacity)
    (make <array>
      (size	0)
      (elements	(when (> capacity 0)
                  (allocate-oop-vector capacity))))))

;;;
;;; self-check
;;;

(define-function arena/expect (what got want)
  (unless (= got want)
    (error "arena self-check failed: " what ": got " got ", want " want)))

(define-function arena/self-check ()
  (let ((prev *globals*))
    (set *globals* *heap-env*)

    (let ((header-size (arena/header-size))
          (cell-bytes  arena/cell-bytes))

      ;; a pair: head is <long> 1, tail <long> 2 (raw words 3 and 5)
      (let ((pair (eval '(cons 1 2))))
        (arena/expect "pair head" (arena/peek-cell pair 0) (arena/tag 1))
        (arena/expect "pair tail" (arena/peek-cell pair 1) (arena/tag 2))
        (let ((header (- (arena/to-host pair) header-size)))
          (arena/expect "pair type"
                        (arena/peek-word-at header 3)
                        (arena/tag (arena/type->slave-id (eval '<pair>))))
          (arena/expect "pair size"
                        (arena/peek-word-at header 1)
                        (arena/tag (* 2 cell-bytes)))
          (arena/expect "pair next"
                        (arena/peek-word-at header 0)
                        header)))

      ;; a string with an empty size slot and an elements pointer
      (let ((str (eval '(string 16))))
        (arena/expect "string size slot" (arena/peek-cell str 0) (arena/tag 0))
        (let ((elements (arena/peek-cell str 1)))
          (unless (and (< 0 elements) (= 0 (bitwise-and elements 1)))
            (error "arena self-check failed: string elements is not a pointer"))))

      ;; an array
      (let ((arr (eval '(array 4))))
        (arena/expect "array size slot" (arena/peek-cell arr 0) (arena/tag 0))
        (let ((elements (arena/peek-cell arr 1)))
          (unless (and (< 0 elements) (= 0 (bitwise-and elements 1)))
            (error "arena self-check failed: array elements is not a pointer")))))

    (set *globals* prev)))

;; The self-check needs the host's natural word to match the target's
;; cell; the cross-width path awaits the typed accessors.
(when (= (eval-in-slave 'target/cell-size/bits) lower/cell-size/bits)
  (arena/self-check))
