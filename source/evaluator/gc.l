;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; A naive precise mark-and-sweep GC.
;;;

;;;
;;; GC header
;;;
;; TODO merge flags and the type id into one cell
(define-record <header> ()
  (next size flags type (when-at-expand (feature object-canary) canary))
  raw-slot-access)

(define-constant size-of-<header> (words-to-bytes (record/effective-slot-count <header>)))

(define-constant <header>-flags/used	1)
(define-constant <header>-flags/opaque	2) ; the GC will not look inside opaque objects
(define-constant <header>-flags/mark	4)

(define-form gc/live-chunk? (header)
  `(bitwise-and <header>-flags/used (<header>-flags ,header)))

(define-form gc/header-of (arg)
  `(- ,arg ,size-of-<header>))

(define-form gc/payload-of (arg)
  `(+ ,arg ,size-of-<header>))

(define-constant +canary-value+ 0xDEADBEE) ; an easy to notice token without any meaning

(define-form gc/valid-header-canary? (header)
  (if (feature object-canary)
      `(= (<header>-canary ,header) ,+canary-value+)
    true))

(define-form gc/initialize-header-canary (header)
  (when (feature object-canary)
    `(set (<header>-canary ,header) ,+canary-value+)))

(define-form gc/valid-maru-value? (obj)
  `(let ((__obj__ ,obj))
     (or (immediate? __obj__)
         ;; NOTE this is to catch low pointers. theoretically this may get false positives if we are running close to the 0 address.
         ;; NOTE we can't use gc/memory-base here, because this may encounter stuff from the read-only memory segment
         (and (< 10000 __obj__)
              ,(if (feature object-canary)
                   '(gc/valid-header-canary? (gc/header-of __obj__))
                 'true)))))

;; TODO this assumes that the read-only data segment is loaded/mapped
;; before the .data segment. it works on linux/elf, but may require
;; more care on other platforms.
(define-form gc/read-only-object? (obj)
  `(< ,obj gc/memory-base))

;;;
;;; tagging
;;;
(define-constant oop/alignment-in-bytes		+word-size-in-bytes+)
(define-constant oop/align-padding		(- oop/alignment-in-bytes 1))
(define-constant oop/payload-mask		(- oop/alignment-in-bytes))
(define-constant oop/tag-mask			(bitwise-not oop/payload-mask))

(define-form oop/align (value)
  `(bitwise-and (+ ,value ,oop/align-padding)
                ,oop/payload-mask))

(define-form aligned-to-oop? (ptr)
  `(= 0 (bitwise-and ,ptr
                     ,oop/tag-mask)))

;; TODO unreified abstraction: NIL is now defined as a full-word
;; immediate using define-immediate in types.l. these macros should be
;; derived based on the actual set of defined types.
;; TODO should this also include a canary check? then it would fail gracefully when used in an (assert (oop? ...))
(define-form oop? (word)
  `(and ,word
        (aligned-to-oop? ,word)))

;; TODO should this check/assert for the actual set of tags? to detect invalid immediate values...
(define-form immediate? (word)
  `(not (oop? ,word)))

;;;
;;; The GC's state
;;;
(define gc/minimum-growth-unit	(* 50 1024))
(define gc/allocations-until-gc	131072)

(define gc/objects-live         0)
(define gc/bytes-used           0)
(define gc/bytes-free           0)

(define gc/roots                0)
(define gc/root-count           0)
(define gc/root-max             0)

(define gc/memory-base          0)
(define gc/memory-last          0)
(define gc/alloc-count          0)
(define gc/collection-count     0)

(define-function gc/acquire-new-heap-space (size)
  (let ((ptr (platform/acquire-memory size)))
    (or ptr (fatal "out of memory"))
    (set (<header>-size  ptr) (- size size-of-<header>))
    (set (<header>-flags ptr) 0)
    (set (<header>-next  ptr) ptr)
    (gc/debug (platform/diag-print "heap growth "(pointer ptr)" size "size" "gc/alloc-count"/"gc/allocations-until-gc"\n"))
    (assert (aligned-to-oop? ptr) "gc/acquire-new-heap-space: aligned-to-oop? has failed for ptr "ptr)
    ptr))

(define-function gc/grow-heap (size)
  (let ((new-block (gc/acquire-new-heap-space size)))
    (set (<header>-next new-block) (<header>-next gc/memory-last))
    (set (<header>-next gc/memory-last) new-block)
    new-block))

(define-function gc/object-size (obj)
  (<header>-size (gc/header-of obj)))

(define-function %next-object-from-header (header)
  (until (gc/live-chunk? header)
    (set header (<header>-next header))
    (when (= header gc/memory-base)
      (return 0)))
  (gc/payload-of header))

(define-function gc/first-object ()
  (%next-object-from-header (<header>-next gc/memory-base)))

(define-function gc/next-object (obj)
  (when obj
    (%next-object-from-header (<header>-next (gc/header-of obj)))))

(define-function gc/sweep ()
  (gc/debug (platform/diag-print "sweep\n"))
  (let ((ptr gc/memory-base)
        (nobjs 0)
        (nused 0)
        (nfree 0))
    (while ptr
      (gc/debug (platform/diag-print "sweep? "(<header>-flags ptr)" "(pointer ptr)" + "(pointer (<header>-size ptr))"\n"))
      (let ((flags (<header>-flags ptr)))
        (if (bitwise-and flags <header>-flags/mark)
            (let ()
              (safety 3 (and (= 0 (<header>-type ptr)) (fatal "gc/sweep: encountered an object with zero type: " (pointer ptr))))
              (set nused (+ nused (<header>-size ptr)))
              (set nobjs (+ nobjs 1))
              (set (<header>-flags ptr) (bitwise-xor flags <header>-flags/mark)))
          (gc/debug (platform/diag-print "collect "(pointer ptr)" size "(<header>-size ptr)"\n"))
          (set nfree (+ nfree (<header>-size ptr)))
          (set (<header>-flags ptr) 0)
          (set (<header>-type ptr) 0)))
      (set ptr (<header>-next ptr))
      (when (= ptr gc/memory-base)
        (set ptr 0)))
    (set gc/objects-live nobjs)
    (set gc/bytes-used nused)
    (set gc/bytes-free nfree)
    (debug (platform/diag-print "GC: "nused" used, "nfree" free, "gc/alloc-count" allocations\n")))
  ())

(define-function gc/mark-and-trace (obj)
  ;; (safety 3 (or (immediate? obj) (< 1000 obj) (fatal "gc/mark-and-trace: encountered a low pointer: " (pointer obj))))
  (and (not (immediate? obj))
       (not (gc/read-only-object? obj))
       (let* ((header (gc/header-of obj))
              (flags  (<header>-flags header)))
         (gc/debug (platform/diag-print "mark and trace "(pointer obj)" ("(pointer header)") flags "flags" size "(<header>-size header)" type "(<header>-type header)"\n"))
         (safety 3
           (or (gc/valid-header-canary? header)
               (fatal "gc/mark-and-trace: encountered an untagged pointer: " (pointer obj))))
         ;; this is typically triggered on (<= 4 *safety*) when a
         ;; gc/let* is missing somewhere, thus an object is not
         ;; recorded as a gc root, and it gets collected.
         (safety 1
           (or (bitwise-and <header>-flags/used flags)
               (fatal "gc/mark-and-trace: reached a dead object: " (pointer header))))
         (or (bitwise-and flags <header>-flags/mark)
             (let ()
               (set (<header>-flags header) (bitwise-or flags <header>-flags/mark))
               (or (bitwise-and flags <header>-flags/opaque)
                   (let ((index (bytes-to-words (<header>-size header))))
                     (gc/debug (platform/diag-print "mark "(pointer header)" wordsize "index" type "(<header>-type header)"\n"))
                     (safety 2 (or (not (= 0 (<header>-type header))) (fatal "gc/mark-and-trace: encountered an object with zero type: " (pointer header))))
                     (while index
                       (decr index)
                       (gc/debug (platform/diag-print "@"index" "(pointer (oop-at obj index))"\n"))
                       ;; (safety 3 (let ((next (oop-at obj index)))
                       ;;             (unless (or (immediate? next)
                       ;;                         (< 1000 next))
                       ;;               (libc/fprintf libc/stderr "gc/mark-and-trace: about to recurse on bogus value: %p; found in the slot %ld of object %p of type %ld\n"
                       ;;                             next index obj (<header>-type header))
                       ;;               ;; enter the debugger
                       ;;               (oop-at 0 0))))
                       (gc/mark-and-trace (oop-at obj index))))))))))

(define-function gc/collect ()
  (set gc/collection-count (+ gc/collection-count 1))
  (gc/debug
   (or (bitwise-and 1023 gc/collection-count)
       (platform/diag-print gc/collection-count " collections")))
  (gc/debug (platform/diag-print "about to mark "gc/root-count" gc roots stored at "(pointer gc/roots)"\n"))
  (gc/mark-and-trace gc/roots) ; even though it's an opaque, we still need to mark the vector itself
  (for (i 0 gc/root-count)
    (let* ((root-ptr	(oop-at gc/roots i))
           (root	(oop-at root-ptr 0)))
      (gc/debug (platform/diag-print "mark gc root "i" : "(pointer root-ptr)" -> "(pointer root)" ("(pointer (gc/header-of root))")\n"))
      (gc/mark-and-trace root)))
  (gc/debug (platform/diag-print "finished marking gc roots\n"))
  (gc/sweep)
  (set gc/alloc-count 0))

(define-function gc/allocate (type requested-size)
  (gc/debug (platform/diag-print "gc/allocate type "type" "requested-size"\n"))
  (safety 2 (assert type "gc/allocate: type is 0"))
  (set requested-size (oop/align requested-size)) ; only allow cell-sized allocation
  (and (= gc/alloc-count gc/allocations-until-gc)
       (gc/collect))
  (let* ((first (<header>-next gc/memory-last))
         (chunk first)
         (total-size (+ requested-size size-of-<header>)))
    (while 1
      (while
        (let ()
          (gc/debug (platform/diag-print "alloc? "(<header>-flags chunk)" "(pointer chunk)" "(pointer (<header>-next chunk))" ["(pointer first)"] "(<header>-size chunk)" >= "requested-size" "(<= requested-size (<header>-size chunk))"\n"))
          (when (= 0 (<header>-flags chunk)) ;; i.e. free chunk
            (let ((chunk-size (<header>-size chunk)))
              (while (and (= 0 (<header>-flags (<header>-next chunk))) ; free
                          ;; TODO can this ever be false?
                          (= (<header>-next chunk) (+ chunk (+ size-of-<header> chunk-size))))
                ;; merge all consecutive free chunks
                (let ((next (<header>-next chunk)))
                  (set (<header>-next chunk) (<header>-next next))
                  (set chunk-size (set (<header>-size chunk) (+ chunk-size (+ size-of-<header> (<header>-size next)))))
                  (when (= next gc/memory-last)
                    (set gc/memory-last chunk))))
              ;; TODO ? total-size includes the header while chunk-size is only the size of the payload space
              (when (or (< total-size chunk-size) ; we'll split this chunk
                        (= requested-size chunk-size)) ; we'll use the entire chunk
                (gc/debug (platform/diag-print "chunk-size "chunk-size"\n"))
                (when (> chunk-size total-size)
                  (let ((split (+ chunk total-size)))
                    (gc/debug (platform/diag-print "split "chunk-size": "(pointer chunk)" + "requested-size" -> "(pointer split)" + "(- chunk-size total-size)"\n"))
                    (set (<header>-size  split) (- chunk-size total-size))
                    (set (<header>-flags split) 0)
                    (set (<header>-next  split) (<header>-next chunk))
                    (set (<header>-size  chunk) requested-size)
                    (set (<header>-next  chunk) split)
                    (set chunk-size requested-size)))
                (gc/debug (platform/diag-print "alloc chunk "(pointer chunk)"\n"))
                (set gc/memory-last chunk)
                (set gc/alloc-count (+ gc/alloc-count 1))
                ;; initialize the freshly reserved chunk
                (let* ((header chunk)
                       (obj (gc/payload-of header)))
                  (set (<header>-flags header) <header>-flags/used)
                  (set (<header>-type header) type)
                  (platform/clear-cells obj (/ chunk-size +word-size-in-bytes+))
                  (safety 4 (assert (= (gc/object-size obj) requested-size) "gc/allocate: was about to return with an object whose size in the header is not equal to the requested size"))
                  (safety 4 (assert (gc/live-chunk? header) "gc/allocate: was about to return with an object whose USED flag is unset"))
                  (safety 3 (gc/initialize-header-canary header))
                  (gc/debug (platform/diag-print "gc/allocate: returning with "(pointer obj)" (header: "(pointer header)"), type "(<header>-type header)", size "(gc/object-size obj)"\n"))
                  (return obj)))))
          (!= first (set chunk (<header>-next chunk)))))
      (gc/grow-heap (max (+ size-of-<header> requested-size)
                         gc/minimum-growth-unit)))))

(define-function gc/allocate-opaque (type requested-size)
  (let* ((obj (gc/allocate type requested-size))
         (header (gc/header-of obj)))
    (set (<header>-flags header) (bitwise-or (<header>-flags header) <header>-flags/opaque))
    obj))

(define-function gc/grow-root-vector ()
  (set gc/root-max (max 32 (* 2 gc/root-max)))
  (let ((new-roots (gc/allocate-opaque <data> (words-to-bytes gc/root-max))))
    (copy-oops gc/roots new-roots gc/root-count)
    (set gc/roots new-roots)))

(define-function gc/push-root (ptr)
  ;; register a pointer to a place that will hold a root
  ;; object. gc/let* uses this.
  (gc/debug (platform/diag-print "gc/push-root "gc/root-count", place "(pointer ptr)"\n"))
  (set (oop-at gc/roots gc/root-count) ptr)
  (incr gc/root-count)
  ;; make sure that there's always space for the next root because otherwise our call to gc/allocate
  ;; could initiate a gc/collect and collect the object before it becomes reachable/protected through the root vector
  (when (= gc/root-count gc/root-max)
    (gc/grow-root-vector)))

(define-function gc/pop-root (ptr)
  (gc/debug (platform/diag-print "gc/pop-root "gc/root-count" at "(pointer ptr)))
  (safety 2 (assert (< 0 gc/root-count) "root table underflow"))
  (decr gc/root-count)
  (safety 2 (assert (= ptr (oop-at gc/roots gc/root-count)) "non-lifo root"))
  (set (oop-at gc/roots gc/root-count) ()))

(define-function gc/initialize ()
  (debug (platform/diag-print "gc/initialize is speaking\n"))
  (let ((ptr (gc/acquire-new-heap-space gc/minimum-growth-unit)))
    (set gc/memory-base ptr)
    (set gc/memory-last ptr))
  (gc/grow-root-vector))

(define-form gc/protect (vars . prog)
  (let ((make-protectors
         (lambda (vars)
           (map (lambda (v) `(gc/push-root (address-of ,v)))
                vars)))
        (make-unprotectors
         (lambda (vars)
           (list-reverse
            (map (lambda (v) `(gc/pop-root (address-of ,v)))
                 vars)))))
    (assert (pair? vars) "the proper syntax is (gc/protect (var1 var2 ...) ...)")
    `(let ()
       ,@(make-protectors vars)
       (let ((__answer__ ,@prog))
         ,@(make-unprotectors vars)
         __answer__))))

(define-form gc/let* (bindings . prog)
  (let ((gc/let*/1))
    (set gc/let*/1 (lambda (bindings prog)
                     (if (pair? bindings)
                         (let ((binding (car bindings)))
                           (unless (pair? binding)
                             (set binding (list binding)))
                           `((let (,binding)
                               (gc/protect (,(car binding))
                                 ,@(gc/let*/1 (cdr bindings) prog)))))
                       prog)))
    (car (gc/let*/1 bindings prog))))
