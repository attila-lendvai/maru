;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; A host-side arena for building the next stage's heap (the genesis).
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

;; The genesis starts at the arena's heap base; gc/initialize stamps
;; a free chunk over the region. Heap growth (platform/acquire-memory)
;; is a bump allocator above it.
(define +arena-capacity+    (* 8 1024 1024))
(define +arena-heap-start+  4096)
(define +arena-region-size+ (* 4 1024 1024))

(define arena/target-64-bit? (= 64 (eval-in-slave 'target/cell-size/bits)))
(define arena/capacity   +arena-capacity+)
(define arena/heap-start +arena-heap-start+)
(define arena/region-end (+ +arena-heap-start+ +arena-region-size+))
(define arena/cursor     arena/region-end)
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
    ((= name 'heap-image-end)		arena/region-end)
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

(define-form heap-value (form)
  `(eval-in-heap ',form))

(define-function define-in-heap (name value)
  (environment-define *heap-env* name value))

(define arena/noop-form
  (form (lambda (*env* . args) ())))

(define arena/noop-function
  (lambda _ ()))

(list-do entry
    `((oop-at			,arena/oop-at)
      (set-oop-at		,arena/set-oop-at)
      (address-of-location	,arena/address-of-location)
      (address-of		,(lambda _ 0))
      (platform/acquire-memory	,arena/acquire)
      (platform/clear-cells	,arena/clear-cells)
      (platform/move-oops	,arena/copy-cells)
      (platform/move-bytes	,arena/copy-bytes)
      (copy-oops		,arena/copy-cells)
      (copy-bytes		,arena/copy-bytes)
      (arena/acquire		,arena/acquire)
      (arena/clear-cells	,arena/clear-cells)
      ;;(arena/header-size	,arena/header-size)
      ;; A debug/fatal shim, so the target sources need no platform layer.
      (debug			,arena/noop-form)
      (debug/identities		,arena/noop-form)
      (gc/debug			,arena/noop-form)
      (debug-print		,arena/noop-form)
      (fatal			,(lambda args (error "arena fatal: " args)))
      (pointer			,(lambda (value) value))
      )

  (let ((name (first entry))
        (value (second entry)))
    (define-in-heap name value)))

(define-function arena/load-target-file (path)
  (let ((prev *globals*))
    (set *globals* *heap-env*)
    (load path)
    (set *globals* prev)))

;;; The header layout, the flags, gc/allocate and gc/initialize.

(arena/load-target-file "source/evaluator/gc.l")

;; No collection runs in the arena, so the root bookkeeping is inert.
;; gc/let* still pushes and pops; address-of above returns 0.
(define-in-heap 'gc/push-root		arena/noop-function)
(define-in-heap 'gc/pop-root		arena/noop-function)

(arena/load-target-file "source/evaluator/types.l")

;; the form machinery calls TYPE-OF on host objects; evaluator/types.l
;; defines a TYPE-OF that reads arena headers. restore the host's.
(define-in-heap 'type-of type-of)

;;; gc/allocate receives type objects from the constructors (compiled
;;; code passes their slave ids instead). Normalize above the shim.

(define arena/slave-id-of (eval-in-slave '<type>-slave-id))

(define-function arena/type->id (type)
  (if (is <long> type) type (arena/slave-id-of type)))

(define-in-heap 'arena/type->id arena/type->id)

(eval-in-heap
 '(define arena/original-gc-allocate gc/allocate))

(eval-in-heap
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

(define-in-heap 'define-vm-function
    (form (lambda (*env* name-and-props args . body)
            (let ((name (if (pair? name-and-props)
                            (car name-and-props)
                          name-and-props)))
              `(define-function ,name
                   ,(arena/vmf-arg-names args)
                 ,@body)))))

(arena/load-target-file "source/evaluator/constructors.l")

;; The arena starts as a real heap: gc/initialize stamps the initial
;; chunk, and the root vector is the first allocation in it, so the
;; runtime can adopt it from the image. Everything compiled afterwards
;; allocates from it.
(eval-in-heap '(gc/initialize false))
(eval-in-heap '(gc/grow-root-vector))
(assert (= (arena/cell->host (eval-in-heap 'gc/roots))
           (+ arena/heap-start (heap-value size-of-<header>)))
        "arena: the root vector is not the first chunk")

;;;
;;; string literals
;;;
;;; compile-object <string> allocates every literal here through the
;;; target's own string constructor, so the emitted object has the same
;;; shape as a runtime-constructed string: a full header, a boxed size
;;; and an opaque <data> body. The body reserves one byte for a NUL, so
;;; string-ensure-zero-terminated never has to mutate a literal.

;; The object labels the emitter must place at a payload: (offset .
;; label). String literals and function objects both need one; the
;; emitter resolves them when it lays out the genesis.
(define arena/labels ())

(define-function arena/register-label (offset label)
  (push arena/labels (cons offset label))
  label)

;; Cells that hold a text address: (offset . label). They are not heap
;; pointers, so the emitter resolves them through the assembler instead
;; of rebasing them.
(define arena/code-pointers ())

(define-function arena/register-code-pointer (offset label)
  (push arena/code-pointers (cons offset label))
  label)

(define arena/literal-counter 0)

(define arena/string-elements-slot
  (record/slot-index (eval-in-heap '<string>) 'elements))

(define arena/long-tag-width (eval-in-heap '(<immediate-type>-tag-width <long>)))
(define arena/long-tag-value (eval-in-heap '(<immediate-type>-tag-value <long>)))

(assert (is <long> arena/long-tag-width)
        "arena: <long> is not an immediate type")

(define-function arena/box-long (value)
  (bitwise-or (bitwise-shift value arena/long-tag-width)
              arena/long-tag-value))

(eval-in-heap
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
    (for (i 0 len)
      (arena/store-u8 (+ elements i) (string-at str i)))
    (arena/store-u8 (+ elements len) 0)
    (arena/register-label offset label)
    (make <arena-literal>
          (offset offset)
          (label  label)
          (source str))))

;;;
;;; function objects
;;;
;;; The target's <target-function> object is built in the arena, so the
;;; runtime reads its code pointer and name from heap cells. The code
;;; pointer cannot be filled here (the code layout is not known yet), so
;;; the slot holds a placeholder and the emitter writes the entry label;
;;; the name is the arena offset of the function's name literal.

(eval-in-heap
 '(define-function arena/new-target-function (name-offset)
    (make/heap <target-function>
      (program-code 0)
      (when-at-expand (feature track-expr-names)
        (name name-offset))
      (when-at-expand (feature profiler)
        (profiler-counter (box <long> 0))))))

;;; The assembler is not loaded yet when this file is compiled, so the
;;; object's label comes from the caller.
(define-function arena/target-function (name entry-label label)
  (let* ((name-offset (if (and name (feature track-expr-names))
                          (<arena-literal>-offset
                           (arena/string-literal (symbol->string name)))
                        0))
         (offset (arena/cell->host
                  (eval-in-heap `(arena/new-target-function ,name-offset)))))
    (arena/register-code-pointer offset entry-label)
    (arena/register-label offset label)
    label))

;;;
;;; the chunk chain
;;;

;; Walk the circular chunk chain and return the chunk headers in address
;; order.
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

;;;
;;; the genesis
;;;

;; Every chunk of the genesis, in address order: the used chunks and the
;; trailing free chunk the image ends with.
(define-function arena/genesis-chain ()
  (arena/chain-headers (eval-in-heap 'gc/memory-base)))

;; The end of the used region: the free chunk that follows the last
;; allocated chunk. When nothing was allocated it is the single free
;; chunk, i.e. the heap start.
(define-function arena/genesis-limit ()
  (arena/peek-word-at
   (arena/cell->host (eval-in-heap 'gc/allocation-cursor)) 0))

;; The image ships one free chunk: the arena's trailing chunk, clipped to
;; the slack. The emitter copies it with the rest of the chain, so the
;; runtime adopts it instead of stamping one.
(define-function arena/clip-genesis-tail! ()
  (let ((size (- +genesis-slack+ (heap-value size-of-<header>))))
    (assert (< 0 size) "arena: the slack does not hold a free chunk header")
    (arena/write-long (+ (arena/genesis-limit) arena/cell-bytes) size)))
