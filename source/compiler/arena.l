;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; A host-side arena for the target's heap.
;;;
;;; The arena is one host <memory-block> addressed by logical byte
;;; offsets. It backs a second heap env in which the target's gc.l,
;;; types.l and constructors.l run against the arena through shims.
;;;
;;; The heap stores raw target words. The heap env is the lower realm,
;;; so its <long>s are plain numbers and arithmetic on them is the
;;; host's raw arithmetic; a <target-cell> carries a raw word read from
;;; the heap. Addresses and cell indices are plain host numbers.
;;;
;;; oop-at and set-oop-at are plain reads and writes of raw words. The
;;; allocator, the chunk chain and the root vector are the target's own
;;; (gc/initialize, gc/allocate); only the platform memory primitives
;;; and the debug hooks are shimmed. Collection never runs here.

;;;
;;; configuration
;;;

;; The initial heap image is the region gc/initialize stamps a free
;; chunk over. Heap growth (platform/acquire-memory) is a bump
;; allocator above it.
(define +arena-capacity+   (* 8 1024 1024))
(define +arena-heap-start+ 4096)
(define +arena-image-size+ (* 4 1024 1024))

(define arena/target-64-bit? (= 64 (eval-in-slave 'target/cell-size/bits)))
(define arena/capacity   +arena-capacity+)
(define arena/heap-start +arena-heap-start+)
(define arena/image-end  (+ +arena-heap-start+ +arena-image-size+))
(define arena/cursor     arena/image-end)
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

;;;
;;; target cells
;;;

;; A target cell read as a raw word. On a 64-bit host with a 64-bit
;; target it is one <u64>; a 32-bit host carries it in two cells.
(define-function arena/read-cell (offset)
  (if arena/target-64-bit?
      (if-at-expand (= 64 lower/cell-size/bits)
          (u64-at arena/block offset)
        (make-u64 (u32-at arena/block offset)
                  (u32-at arena/block (+ offset 4))))
    (u32-at arena/block offset)))

(define-function arena/write-cell (offset cell)
  (if arena/target-64-bit?
      (if-at-expand (= 64 lower/cell-size/bits)
          (set-u64-at arena/block offset cell)
        (let ()
          (set-u32-at arena/block offset (<u64>-lo cell))
          (set-u32-at arena/block (+ offset 4) (<u64>-hi cell))))
    (set-u32-at arena/block offset cell)))

;; A plain <long> is written as its raw bits, zero extended to the
;; target's cell width.
(define-function arena/write-long (offset value)
  (if arena/target-64-bit?
      (if-at-expand (= 64 lower/cell-size/bits)
          (set-u64-at arena/block offset value)
        (let ()
          (set-u32-at arena/block offset (bitwise-and value 0xffffffff))
          (set-u32-at arena/block (+ offset 4) (bitwise-shift value -32))))
    (set-u32-at arena/block offset (bitwise-and value 0xffffffff))))

;; Addresses, indices and counts are small enough to fit the low half
;; of a two-cell <u64>.
(define-function arena/cell->host (cell)
  (cond
    ((is <long> cell) cell)
    ((is <lower-cell> cell) (lower-cell->long cell))
    ((is <u32> cell) (lower-cell->long (u32->u64 cell)))
    ((is <u64> cell) (lower-cell->long (<u64>-lo cell)))
    (else
     (error "arena/cell->host: unexpected value " cell))))

(define-function arena/acquire (size)
  (let* ((size	(bitwise-and (+ size (- arena/cell-bytes 1))
                              (- arena/cell-bytes)))
         (start	arena/cursor)
         (end	(+ start size)))
    (unless (<= end arena/capacity)
      (error "arena: out of memory: capacity " arena/capacity
             ", requested " size))
    (set arena/cursor end)
    start))

;;;
;;; the shims
;;;

;; Host objects (type objects, forms) may reach the shims; the arena
;; buffer itself only ever sees target words.
(define arena/host-oop-at oop-at)
(define arena/host-set-oop-at set-oop-at)

(define-function arena/oop-at (base index)
  (if (or (is <target-cell> base) (is <long> base))
      (arena/read-cell (+ (arena/cell->host base)
                          (* (arena/cell->host index) arena/cell-bytes)))
    (arena/host-oop-at base index)))

(define-function arena/set-oop-at (base index value)
  (if (or (is <target-cell> base) (is <long> base))
      (let ((offset (+ (arena/cell->host base)
                       (* (arena/cell->host index) arena/cell-bytes))))
        (cond
          ((is <target-cell> value) (arena/write-cell offset value))
          ((is <long> value) (arena/write-long offset value))
          (else
           (error "arena/set-oop-at: not a target word: " value))))
    (arena/host-set-oop-at base index value)))

(define-function arena/address-of-location (name)
  (cond
    ((= name 'heap-image-start)		arena/heap-start)
    ((= name 'heap-image-end)		arena/image-end)
    ((= name 'read-only-space-start)	0)
    ((= name 'read-only-space-end)	0)
    ((= name 'static-space-start)	0)
    ((= name 'static-space-end)		0)
    (else
     (error "arena: unknown location: " name))))

(define-function arena/clear-cells (base count)
  (let ((offset (arena/cell->host base))
        (i 0))
    (while (< i count)
      (arena/write-long (+ offset (* i arena/cell-bytes)) 0)
      (incr i))))

(define-function arena/copy-cells (from to count)
  (let ((src (arena/cell->host from))
        (dst (arena/cell->host to))
        (i 0))
    (while (< i count)
      (arena/write-cell (+ dst (* i arena/cell-bytes))
                        (arena/read-cell (+ src (* i arena/cell-bytes))))
      (incr i))))

(define-function arena/copy-bytes (from to count)
  (let ((src (arena/cell->host from))
        (dst (arena/cell->host to))
        (i 0))
    (while (< i count)
      (arena/store-u8 (+ dst i) (arena/load-u8 (+ src i)))
      (incr i))))

;;;
;;; peeking, for the scan and the verification
;;;

(define-function arena/peek-word (offset)
  (let ((lo (arena/load-u32 offset)))
    (if arena/target-64-bit?
        (let ((hi (arena/load-u32 (+ offset 4))))
          (if-at-expand (= 64 lower/cell-size/bits)
              (+ lo (bitwise-shift hi 32))
            (if (= 0 hi)
                lo
              (error "arena: peeked word exceeds a 32-bit host"))))
      lo)))

(define-function arena/peek-word-at (offset index)
  (arena/peek-word (+ offset (* index arena/cell-bytes))))

(define-function arena/peek-cell (base index)
  (arena/peek-word-at (arena/cell->host base) index))

;;;
;;; the heap env
;;;

(let ((heap-env (environment *slave-env*)))
  (assert (= 0 (<env>-level heap-env)))
  (define *heap-env* heap-env))

(define-function eval-in-heap (form)
  (eval form *heap-env*))

(define-function arena/header-size ()
  (eval-in-heap 'size-of-<header>))

(environment-define *heap-env* 'oop-at			arena/oop-at)
(environment-define *heap-env* 'set-oop-at		arena/set-oop-at)
(environment-define *heap-env* 'address-of-location	arena/address-of-location)
(environment-define *heap-env* 'address-of		(lambda (value) 0))
(environment-define *heap-env* 'platform/acquire-memory	arena/acquire)
(environment-define *heap-env* 'platform/clear-cells	arena/clear-cells)
(environment-define *heap-env* 'platform/move-oops	arena/copy-cells)
(environment-define *heap-env* 'platform/move-bytes	arena/copy-bytes)
(environment-define *heap-env* 'copy-oops		arena/copy-cells)
(environment-define *heap-env* 'copy-bytes		arena/copy-bytes)
(environment-define *heap-env* 'arena/acquire		arena/acquire)
(environment-define *heap-env* 'arena/clear-cells	arena/clear-cells)
(environment-define *heap-env* 'arena/header-size	arena/header-size)

(define-function arena/load-target-file (path)
  (let ((prev *globals*))
    (set *globals* *heap-env*)
    (load path)
    (set *globals* prev)))

(define-function arena/heap-define (form)
  (let ((prev *globals*))
    (set *globals* *heap-env*)
    (eval form)
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

;;; The header layout, the flags, gc/allocate and gc/initialize.

(arena/load-target-file "source/evaluator/gc.l")

;; No collection runs in the arena, so the root bookkeeping is inert.
;; gc/let* still pushes and pops; address-of above returns 0.
(environment-define *heap-env* 'gc/push-root (lambda (ptr) ()))
(environment-define *heap-env* 'gc/pop-root  (lambda (ptr) ()))

(arena/load-target-file "source/evaluator/types.l")

;; the form machinery calls TYPE-OF on host objects; evaluator/types.l
;; defines a TYPE-OF that reads arena headers. restore the host's.
(define arena/host-type-of type-of)
(environment-define *heap-env* 'type-of arena/host-type-of)

;;; gc/allocate receives type objects from the constructors (compiled
;;; code passes their slave ids instead). Normalize above the shim.

(define arena/slave-id-of (eval-in-slave '<type>-slave-id))

(define-function arena/type->id (type)
  (if (is <long> type) type (arena/slave-id-of type)))

(environment-define *heap-env* 'arena/type->id arena/type->id)

(arena/heap-define '(define arena/original-gc-allocate gc/allocate))

(arena/heap-define
 '(define-function gc/allocate (type requested-size opaque?)
    (arena/original-gc-allocate (arena/type->id type)
                                requested-size opaque?)))

;;; constructors.l uses define-vm-function to generate the evaluator
;;; stubs. The arena calls the target-domain implementations directly,
;;; so only the implementation is generated here.

(define-function arena/vmf-arg-names (args)
  (if (= '_ args)
      ()
    (map (lambda (entry) (car (ensure-list entry))) args)))

(environment-define *heap-env* 'define-vm-function
                    (form (lambda (*env* name-and-props args . body)
                            (let ((name (if (pair? name-and-props)
                                            (car name-and-props)
                                          name-and-props)))
                              `(define-function ,name
                                 ,(arena/vmf-arg-names args)
                                 ,@body)))))

(arena/load-target-file "source/evaluator/constructors.l")

;; The arena starts as a real heap: gc/initialize stamps the initial
;; chunk and builds the root vector. Everything compiled afterwards
;; allocates from it.
(eval-in-heap '(gc/initialize))

;;;
;;; string literals
;;;
;;; compile-object <string> allocates every literal here through the
;;; target's own string constructor, so the emitted object has the same
;;; shape as a runtime-constructed string: a full header, a boxed size
;;; and an opaque <data> body. The body reserves one byte for a NUL, so
;;; string-ensure-zero-terminated never has to mutate a literal.

(define arena/literals ())
(define arena/literals-start ())
(define arena/literal-counter 0)

(define arena/string-size-slot
  (record/slot-index (eval-in-heap '<string>) 'size))
(define arena/string-elements-slot
  (record/slot-index (eval-in-heap '<string>) 'elements))

(define arena/long-tag-width (eval-in-heap '(<immediate-type>-tag-width <long>)))
(define arena/long-tag-value (eval-in-heap '(<immediate-type>-tag-value <long>)))

(assert (is <long> arena/long-tag-width)
        "arena: <long> is not an immediate type")

(define-function arena/box-long (value)
  (bitwise-or (bitwise-shift value arena/long-tag-width)
              arena/long-tag-value))

(arena/heap-define
 '(define-function arena/new-string (len)
    (let ((s (string (+ len 1))))
      (set (<string>-size s) (box <long> len))
      s)))

(define-record <arena-literal> () (offset label source))

(define-function arena/string-literal (str)
  (let* ((len		(string-length str))
         (label		(string->symbol
                         (concat-strings "str."
                                         (integer->string
                                          (incr arena/literal-counter)))))
         (obj		(eval-in-heap `(arena/new-string ,len)))
         (offset	(arena/cell->host obj))
         (elements	(arena/peek-word-at offset arena/string-elements-slot)))
    (unless arena/literals-start
      (set arena/literals-start (- offset (arena/header-size))))
    (for (i 0 len)
      (arena/store-u8 (+ elements i) (string-at str i)))
    (arena/store-u8 (+ elements len) 0)
    (let ((literal (make <arena-literal>
                         (offset offset)
                         (label  label)
                         (source str))))
      (push arena/literals literal)
      literal)))

;;;
;;; scan-validate
;;;

;; Walk the circular chunk chain and check that every pointer word in a
;; live, non-opaque payload points at a live header. Raw numbers and
;; immediates are skipped (the same oop? test gc.l uses).
(define-function arena/chain-headers (base)
  (let ((headers ())
        (header  base)
        (done    ())
        (count   0))
    (while (not done)
      (push headers header)
      (let ((next (arena/peek-word-at header 0)))
        (unless (and (< 0 next) (<= next arena/capacity))
          (error "arena scan: bad chunk link at " header ": " next))
        (set header next))
      (incr count)
      (when (= header base)
        (set done true))
      (when (> count 100000)
        (error "arena scan: the chunk chain does not terminate")))
    (list-reverse! headers)))

(define-function arena/scan-validate ()
  (let* ((header-size (arena/header-size))
         (tag-mask    (eval-in-heap 'oop/tag-mask))
         (used        (eval-in-heap '<header>-flags/used))
         (opaque      (eval-in-heap '<header>-flags/opaque))
         (base        (eval-in-heap 'gc/memory-base))
         (headers     (arena/chain-headers base))
         (chunk       base)
         (done        ()))
    (while (not done)
      (let ((flags (arena/peek-word-at chunk 2))
            (size  (arena/peek-word-at chunk 1)))
        (unless (and (<= 0 size)
                     (= 0 (bitwise-and size (- arena/cell-bytes 1))))
          (error "arena scan: bad chunk size at " chunk ": " size))
        (when (and (= used (bitwise-and used flags))
                   (= 0 (bitwise-and opaque flags)))
          (let ((cells (/ size arena/cell-bytes))
                (obj   (+ chunk header-size))
                (i     0))
            (while (< i cells)
              (let ((word (arena/peek-word-at obj i)))
                (when (and (!= 0 word)
                           (= 0 (bitwise-and word tag-mask)))
                  (unless (member? (- word header-size) headers)
                    (error "arena scan: dangling pointer " word
                           " in the payload of " chunk))))
              (incr i))))
        (set chunk (arena/peek-word-at chunk 0))
        (when (= chunk base)
          (set done true))))
    (list-length headers)))

;;;
;;; the image
;;;

(define arena/flags-used   (eval-in-heap '<header>-flags/used))
(define arena/flags-opaque (eval-in-heap '<header>-flags/opaque))

;; The used chunks of the image, in address order. The root vector and
;; the free chunk are outside [literals-start, ...).
(define-function arena/image-chunks ()
  (if (not arena/literals-start)
      ()
    (let ((chunks ()))
      (list-do header (arena/chain-headers (eval-in-heap 'gc/memory-base))
        (when (and (<= arena/literals-start header)
                   (= arena/flags-used
                      (bitwise-and arena/flags-used
                                   (arena/peek-word-at header 2))))
          (push chunks header)))
      (list-reverse! chunks))))

;;;
;;; verification
;;;

(define-function arena/expect (what got want)
  (unless (= got want)
    (error "arena check failed: " what ": got " got ", want " want)))

(define-function arena/verify-literals ()
  (let* ((header-size (arena/header-size))
         (cell-bytes  arena/cell-bytes)
         (string-id   (eval-in-heap '(<type>-slave-id <string>)))
         (data-id     (eval-in-heap '(<type>-slave-id <data>)))
         (used        (eval-in-heap '<header>-flags/used))
         (opaque      (eval-in-heap '<header>-flags/opaque))
         (count       0)
         (bytes       0))
    (list-do literal arena/literals
      (let* ((offset   (<arena-literal>-offset literal))
             (source   (<arena-literal>-source literal))
             (len      (string-length source))
             (header   (- offset header-size))
             (size     (arena/peek-word-at offset arena/string-size-slot))
             (elements (arena/peek-word-at offset arena/string-elements-slot))
             (el-header (- elements header-size)))
        (arena/expect "literal type" (arena/peek-word-at header 3) string-id)
        (arena/expect "literal flags" (arena/peek-word-at header 2) used)
        (arena/expect "literal size" size (arena/box-long len))
        (arena/expect "elements alignment"
                      (bitwise-and elements (- cell-bytes 1)) 0)
        (arena/expect "elements type" (arena/peek-word-at el-header 3) data-id)
        (arena/expect "elements flags" (arena/peek-word-at el-header 2)
                      (bitwise-or used opaque))
        (unless (<= (+ len 1) (arena/peek-word-at el-header 1))
          (error "arena: string literal body is too small for its NUL: " len))
        (for (i 0 len)
          (unless (= (arena/load-u8 (+ elements i)) (string-at source i))
            (error "arena: string literal byte mismatch at " i)))
        (arena/expect "literal NUL" (arena/load-u8 (+ elements len)) 0)
        (incr count)
        (set bytes (+ bytes (+ len 1)))))
    (arena/scan-validate)
    (verbosity 1
      (warn "arena: " count " string literals, " bytes " bytes\n"))))

