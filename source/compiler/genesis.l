;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; The genesis: the next stage's heap, built on the host while compiling.
;;;
;;; The genesis lives in one host <memory-block> addressed by logical byte
;;; offsets. It backs a second env, the genesis env, in which the
;;; target's gc.l, types.l and constructors.l run against the genesis
;;; through shims.
;;;
;;; The genesis stores raw target words. The env is the lower realm,
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

;; The genesis starts at the block's heap base; gc/initialize stamps
;; a free chunk over the region. Heap growth (platform/acquire-memory)
;; is a bump allocator above it, from genesis/region-end up.
(define genesis/capacity    (* 8 1024 1024))
(define genesis/heap-start  4096)
(define genesis/region-size (* 4 1024 1024))
(define genesis/region-end  (+ genesis/heap-start genesis/region-size))

(define genesis/target-64-bit? (= 64 (eval-in-slave 'target/cell-size/bits)))
(define genesis/growth-cursor genesis/region-end)
(define genesis/cell-bytes (if genesis/target-64-bit? 8 4))

(define genesis/block (memory-block genesis/capacity))

;; grow the block's logical size to its capacity, so that reads of
;; unwritten bytes return zero instead of nil
(set-u8-at genesis/block (- genesis/capacity 1) 0)

;;;
;;; raw byte access
;;;

(define-function %genesis/assert-range (offset size)
  (unless (and (<= 0 offset) (<= (+ offset size) genesis/capacity))
    (error "genesis: access out of range: offset " offset ", size " size)))

(define-function genesis/load-u8 (offset)
  (%genesis/assert-range offset 1)
  (u8-at genesis/block offset))

(define-function genesis/store-u8 (offset value)
  (%genesis/assert-range offset 1)
  (set (u8-at genesis/block offset)
       (bitwise-and value 0xff))
  value)

(define-function genesis/load-u32 (offset)
  (%genesis/assert-range offset 4)
  (bitwise-or (u8-at genesis/block offset)
              (bitwise-shift (u8-at genesis/block (+ offset 1)) 8)
              (bitwise-shift (u8-at genesis/block (+ offset 2)) 16)
              (bitwise-shift (u8-at genesis/block (+ offset 3)) 24)))

;;;
;;; target cells
;;;

;; A target cell read as a raw word. On a 64-bit host with a 64-bit
;; target it is one <u64>; a 32-bit host carries it in two cells.
(define-function genesis/read-cell (offset)
  (if genesis/target-64-bit?
      (if-at-expand (= 64 lower/cell-size/bits)
          (u64-at genesis/block offset)
        (make-u64 (genesis/load-u32 offset)
                  (genesis/load-u32 (+ offset 4))))
    (u32-at genesis/block offset)))

(define-function genesis/write-cell (offset cell)
  (if genesis/target-64-bit?
      (if-at-expand (= 64 lower/cell-size/bits)
          (set-u64-at genesis/block offset cell)
        (let ()
          (set-u32-at genesis/block offset (<u64>-lo cell))
          (set-u32-at genesis/block (+ offset 4) (<u64>-hi cell))))
    (set-u32-at genesis/block offset cell)))

;; A plain <long> is written as its raw bits, zero extended to the
;; target's cell width.
(define-function genesis/write-long (offset value)
  (if genesis/target-64-bit?
      (if-at-expand (= 64 lower/cell-size/bits)
          (set-u64-at genesis/block offset value)
        (let ()
          (set-u32-at genesis/block offset (bitwise-and value 0xffffffff))
          (set-u32-at genesis/block (+ offset 4) (bitwise-shift value -32))))
    (set-u32-at genesis/block offset (bitwise-and value 0xffffffff))))

;; Addresses, indices and counts are small enough to fit the low half
;; of a two-cell <u64>.
(define-function genesis/cell->host (cell)
  (typecase cell
    (<long>		cell)
    (<lower-cell>	(lower-cell->long cell))
    (<u32>		(lower-cell->long (u32->u64 cell)))
    (<u64>		(lower-cell->long (<u64>-lo cell)))
    (else
     (error "genesis/cell->host: unexpected value " cell))))

(define-function genesis/acquire (size)
  (let* ((size	(bitwise-and (+ size (- genesis/cell-bytes 1))
                              (- genesis/cell-bytes)))
         (start	genesis/growth-cursor)
         (end	(+ start size)))
    (unless (<= end genesis/capacity)
      (error "genesis: out of memory: capacity " genesis/capacity
             ", requested " size))
    (set genesis/growth-cursor end)
    start))

;;;
;;; the shims
;;;

;; Host objects (type objects, forms) may reach the shims; the genesis
;; block itself only ever sees target words.
(define genesis/host-oop-at oop-at)
(define genesis/host-set-oop-at set-oop-at)

(define-function genesis/oop-at (base index)
  (if (or (is <target-cell> base) (is <long> base))
      (genesis/read-cell (+ (genesis/cell->host base)
                            (* (genesis/cell->host index) genesis/cell-bytes)))
    (genesis/host-oop-at base index)))

(define-function genesis/set-oop-at (base index value)
  (if (or (is <target-cell> base) (is <long> base))
      (let ((offset (+ (genesis/cell->host base)
                       (* (genesis/cell->host index) genesis/cell-bytes))))
        (cond
          ((is <target-cell> value) (genesis/write-cell offset value))
          ((is <long> value) (genesis/write-long offset value))
          (else
           (error "genesis/set-oop-at: not a target word: " value))))
    (genesis/host-set-oop-at base index value)))

(define-function genesis/address-of-location (name)
  (case name
    (heap-image-start		genesis/heap-start)
    (heap-image-end		genesis/region-end)
    (read-only-space-start	0)
    (read-only-space-end	0)
    (static-space-start		0)
    (static-space-end		0)
    (else
     (error "genesis: unknown location: " name))))

(define-function genesis/clear-cells (base count)
  (let ((offset (genesis/cell->host base))
        (i 0))
    (while (< i count)
      (genesis/write-long (+ offset (* i genesis/cell-bytes)) 0)
      (incr i))))

(define-function genesis/copy-cells (from to count)
  (let ((src (genesis/cell->host from))
        (dst (genesis/cell->host to))
        (i 0))
    (while (< i count)
      (genesis/write-cell (+ dst (* i genesis/cell-bytes))
                          (genesis/read-cell (+ src (* i genesis/cell-bytes))))
      (incr i))))

(define-function genesis/copy-bytes (from to count)
  (let ((src (genesis/cell->host from))
        (dst (genesis/cell->host to))
        (i 0))
    (while (< i count)
      (genesis/store-u8 (+ dst i) (genesis/load-u8 (+ src i)))
      (incr i))))

(define-function genesis/cell-at (offset cell-index)
  (let* ((address	(+ offset (* cell-index genesis/cell-bytes)))
         (lo		(genesis/load-u32 address)))
    (if genesis/target-64-bit?
        (let ((hi (genesis/load-u32 (+ address 4))))
          (if-at-expand (= 64 lower/cell-size/bits)
              (+ lo (bitwise-shift hi 32))
            (if (= 0 hi)
                lo
              (error "genesis/cell-at: cell value exceeds a 32-bit host"))))
      lo)))

;;;
;;; The Genesis env
;;;
;;; We load the memory-layout related part of the n+1 into the
;;; *genesis-env* and evaluate it to construct the initial heap of the
;;; n+1 (that we call genesis).

(let ((genesis-env (environment *slave-env*)))
  (assert (= 0 (<env>-level genesis-env)))
  (define *genesis-env* genesis-env))

(define-function eval-in-genesis (form)
  (eval form *genesis-env*))

(define-form genesis-value (form)
  `(eval-in-genesis ',form))

(define-function define-in-genesis (name value)
  (environment-define *genesis-env* name value))

(define genesis/noop-form
  (form (lambda (*env* . args) ())))

(define genesis/noop-function
  (lambda _ ()))

(list-do entry
    `((oop-at			,genesis/oop-at)
      (set-oop-at		,genesis/set-oop-at)
      (address-of-location	,genesis/address-of-location)
      (address-of		,(lambda _ 0))
      (platform/acquire-memory	,genesis/acquire)
      (platform/clear-cells	,genesis/clear-cells)
      (platform/move-oops	,genesis/copy-cells)
      (platform/move-bytes	,genesis/copy-bytes)
      (copy-oops		,genesis/copy-cells)
      (copy-bytes		,genesis/copy-bytes)
      (genesis/acquire		,genesis/acquire)
      (genesis/clear-cells	,genesis/clear-cells)
      ;;(genesis/header-size	,genesis/header-size)
      ;; A debug/fatal shim, so the target sources need no platform layer.
      (debug			,genesis/noop-form)
      (debug/identities		,genesis/noop-form)
      (gc/debug			,genesis/noop-form)
      (debug-print		,genesis/noop-form)
      (fatal			,(lambda args (error "genesis fatal: " args)))
      (pointer			,(lambda (value) value))
      )

  (let ((name (first entry))
        (value (second entry)))
    (define-in-genesis name value)))

(define-function genesis/load-target-file (path)
  (let ((prev *globals*))
    (set *globals* *genesis-env*)
    (load path)
    (set *globals* prev)))

;;; The header layout, the flags, gc/allocate and gc/initialize.

(genesis/load-target-file "source/evaluator/gc.l")

;; No collection runs in the genesis, so the root bookkeeping is inert.
;; gc/let* still pushes and pops; address-of above returns 0.
(define-in-genesis 'gc/push-root		genesis/noop-function)
(define-in-genesis 'gc/pop-root		genesis/noop-function)

(genesis/load-target-file "source/evaluator/types.l")

;; the form machinery calls TYPE-OF on host objects; evaluator/types.l
;; defines a TYPE-OF that reads genesis headers. restore the host's.
(define-in-genesis 'type-of type-of)

;;; gc/allocate receives type objects from the constructors (compiled
;;; code passes their slave ids instead). Normalize above the shim.

(define genesis/slave-id-of (eval-in-slave '<type>-slave-id))

(define-function genesis/type->id (type)
  (if (is <long> type) type (genesis/slave-id-of type)))

(define-in-genesis 'genesis/type->id genesis/type->id)

(eval-in-genesis
 '(define genesis/original-gc-allocate gc/allocate))

(eval-in-genesis
 '(define-function gc/allocate (type requested-size opaque?)
   (genesis/original-gc-allocate (genesis/type->id type)
    requested-size opaque?)))

;;; constructors.l uses define-vm-function to generate the evaluator
;;; stubs. The genesis builder calls the target-domain implementations
;;; directly, so only the implementation is generated here.

(define-function genesis/vmf-arg-names (args)
  (if (= '_ args)
      ()
    (map (lambda (entry) (car (ensure-list entry))) args)))

(define-in-genesis 'define-vm-function
    (form (lambda (*env* name-and-props args . body)
            (let ((name (if (pair? name-and-props)
                            (car name-and-props)
                          name-and-props)))
              `(define-function ,name
                   ,(genesis/vmf-arg-names args)
                 ,@body)))))

(genesis/load-target-file "source/evaluator/constructors.l")

;; The genesis starts as a real heap: gc/initialize stamps the initial
;; chunk, and the root vector is the first allocation in it, so the
;; runtime can adopt it from the image. Everything compiled afterwards
;; allocates from it.
(eval-in-genesis '(gc/initialize false))
(eval-in-genesis '(gc/grow-root-vector))
(assert (= (genesis/cell->host (eval-in-genesis 'gc/roots))
           (+ genesis/heap-start (genesis-value size-of-<header>)))
        "genesis: the root vector is not the first chunk")

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
(define genesis/labels ())

(define-function genesis/register-label (offset label)
  (push genesis/labels (cons offset label))
  label)

;; Cells that hold a text address: (offset . label). They are not heap
;; pointers, so the emitter resolves them through the assembler instead
;; of rebasing them.
(define genesis/code-pointers ())

(define-function genesis/register-code-pointer (offset label)
  (push genesis/code-pointers (cons offset label))
  label)

(define genesis/literal-counter 0)

(define-record <genesis-literal> ()
  (offset
   label
   ))

(define-function genesis/string-literal (str)
  (let* ((len		(string-length str))
         (label		(string->symbol
                         (concat-strings "str."
                                         (integer->string
                                          (incr genesis/literal-counter)))))
         (obj		(eval-in-genesis `(string/heap ,(+ len 1))))
         ;; TODO drop the genesis/cell->host mapping, and offset
         ;; entirely. but that requires the array accessors to
         ;; understand <u32> and <u64> as index.
         (offset	(genesis/cell->host obj))
         (elements	(genesis/cell->host (eval-in-genesis `(<string>-elements ,obj)))))
    ;; TODO if array.l were loaded...
    ;; (for (i 0 len)
    ;;   (let ((c (string-at str i)))
    ;;     (eval-in-genesis
    ;;      `(string-append ,obj ,c))))
    ;; (eval-in-genesis `(set (string-at ,obj ,len) 0))

    ;; copy the contents
    (for (i 0 len)
      (genesis/store-u8 (+ elements i) (string-at str i)))
    (genesis/store-u8 (+ elements len) 0) ; zero terminated: an optimization for C interop
    (eval-in-genesis `(set (<string>-size ,obj) (box <long> ,len)))

    (genesis/register-label offset label)

    (make <genesis-literal>
      (offset offset)
      (label  label))))

;;;
;;; function objects
;;;
;;; The target's <target-function> object is built in the genesis, so the
;;; runtime reads its code pointer and name from heap cells. The code
;;; pointer cannot be filled here (the code layout is not known yet), so
;;; the slot holds a placeholder and the emitter writes the entry label;
;;; the name is the genesis offset of the function's name literal.

(eval-in-genesis
 '(define-function genesis/new-target-function (name-offset)
    (make/heap <target-function>
      (program-code 0)
      (when-at-expand (feature track-expr-names)
        (name name-offset))
      (when-at-expand (feature profiler)
        (profiler-counter (box <long> 0))))))

;;; The assembler is not loaded yet when this file is compiled, so the
;;; object's label comes from the caller.
(define-function genesis/target-function (name entry-label label)
  (let* ((name-offset (if (and name (feature track-expr-names))
                          (<genesis-literal>-offset
                           (genesis/string-literal (symbol->string name)))
                        0))
         (offset (genesis/cell->host
                  (eval-in-genesis `(genesis/new-target-function ,name-offset)))))
    (genesis/register-code-pointer offset entry-label)
    (genesis/register-label offset label)
    label))

;;;
;;; the chunk chain
;;;

;; Walk the circular chunk chain and return the chunk headers in address
;; order.
(define-function genesis/walk-chain (base)
  (let ((headers ())
        (header  base)
        (done    ())
        (count   0))
    (while (not done)
      (push headers header)
      (let ((next (genesis/cell-at header 0)))
        (unless (and (< 0 next) (<= next genesis/capacity))
          (error "genesis scan: bad chunk link at " header ": " next))
        (set header next))
      (incr count)
      (when (= header base)
        (set done true))
      (when (> count 100000)
        (error "genesis scan: the chunk chain does not terminate")))
    (list-reverse! headers)))

;; Every chunk of the genesis, in address order: the used chunks and the
;; trailing free chunk the image ends with.
(define-function genesis/chain ()
  (genesis/walk-chain (eval-in-genesis 'gc/memory-base)))

;; The end of the used region: the free chunk that follows the last
;; allocated chunk. When nothing was allocated it is the single free
;; chunk, i.e. the heap start.
(define-function genesis/limit ()
  (genesis/cell-at
   (genesis/cell->host (eval-in-genesis 'gc/allocation-cursor)) 0))

;; The image ships one free chunk: the genesis's trailing chunk, clipped
;; to the slack. The emitter copies it with the rest of the chain, so the
;; runtime adopts it instead of stamping one.
(define-function genesis/clip-tail! ()
  (let ((size (- +genesis-slack+ (genesis-value size-of-<header>))))
    (assert (< 0 size) "genesis: the slack does not hold a free chunk header")
    (genesis/write-long (+ (genesis/limit) genesis/cell-bytes) size)))
