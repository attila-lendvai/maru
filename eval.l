;;; The Maru VM, written in a subset of Maru.

(define-form k/assert		prog ())
(define-form debug		prog ())
(define-form debug/identities	prog ())
(define-form gc/debug		prog ())

;;
;; you can enable safety and debugging features here
;;
;; TODO use print-to-string eventually to generate the default assertion message, or add support for list literals in the compiler
(define-form k/assert		(test . args)	`(or ,test (k/error ,@(or args (list "kernel assertion failed")))))
;(define-form debug		prog		`(let () ,@prog))
;(define-form debug/identities	prog		`(let () ,@prog))
;(define-form gc/debug		prog		`(let () ,@prog))

;; This variable controls the amount of safety features compiled
;; into the runtime, at the cost of execution speed.
(define safety-level 0)

(define-form safety (level . prog)
  (when (<= level safety-level)
    `(let () ,@prog)))

;;;
;;; Naming convention in this file:
;;;
;;; vm     - Virtual Machine, i.e. a universe capable of executing code.
;;;          It has its own set of laws that are accepted as axioms.
;;;
;;; host   - The Maru vm running the compiler.
;;;
;;; target - The target vm of the "level-shift" operation (e.g. x86 asm).
;;;
;;; kernel - It's the part of the semantic space that runs on the target.
;;;          e.g. k/apply vs. subr/apply (which uses k/apply in its
;;;          implementation).
;;;
;;; k/ prefix means that it's something that is part of the kernel of the
;;;    codebase, i.e. the stuff that implements the Maru vm. Often it's
;;;    necessary to distinguish a name that exists both in the Maru vm,
;;;    and in the kernel (e.g. car and k/car). It's not exhasutive, i.e.
;;;    not all that is part of the kernel is prefixed with k/.
;;;
;;; slave  - The Maru vm that is being bootstrapped and will
;;;          spring to life when the result of the level-shift
;;;          (the compilation) gets executed on the target.
;;;          Its name comes from the idea that, having a dynamic compiler,
;;;          the host could start up the slave vm under its full
;;;          supervision.
;;;
;;; oop    - Ordinary Object Pointer
;;;
;;; get, put, is
;;;        - These are the kernel "accessors" for Maru values.
;;;          They are also used as a namespace, e.g. get/long.
;;;
;;; subr/ prefix denotes the subr's, the primitive functions that will
;;;       be made visible to user code in the bootstrapped Maru
;;;       semantic space as part of the laws of the slave vm.
;;;
;;; *foo* is global
;;; +foo+ is a constant
;;; -foo- comes from the implicit lexical scope
;;; <foo> is a type
;;;
;;; size means bytes; if not, then it should be indicated.

;;;
;;; Implementation details:
;;;
;;;  - () is the false value, and is mapped to 0 in the target. Its type is the <undefined> type,
;;;    which is denoted in the target by some integer assigned as per the type definition order.
;;;

(define-constant target-word-size/bits	32)
(define-constant target-word-size/bytes	(/ target-word-size/bits 8))

(define-form bytes-to-words (value)
  (if (long? value)
      (/  value  target-word-size/bytes)
     `(/ ,value ,target-word-size/bytes)))

(define-form words-to-bytes (value)
  (if (long? value)
      (* value   target-word-size/bytes)
     `(* ,value ,target-word-size/bytes)))

(define-constant immediate-type/max-tag-width	(let ((result 0))
                                                  (array-do x %immediate-type/tag-widths
                                                    (when x
                                                      (set result (max result x))))
                                                  result))

(when (< target-word-size/bytes
         (<< 1 immediate-type/max-tag-width))
  (warn "immediate-type/max-tag-width ("immediate-type/max-tag-width") will force a stronger alignment for OOP's than what the target word size demands\n"))

(define-constant oop/alignment-in-bytes		(max target-word-size/bytes (<< 1 immediate-type/max-tag-width)))
(define-constant oop/align-padding		(- oop/alignment-in-bytes 1))
(define-constant oop/payload-mask		(- oop/alignment-in-bytes))
(define-constant oop/tag-mask			(^ oop/payload-mask -1))

;;(warn "oop/alignment-in-bytes is "oop/alignment-in-bytes", oop/align-padding is "oop/align-padding", oop/payload-mask is "oop/payload-mask", oop/tag-mask is "oop/tag-mask"\n")

(define-form oop/align (value)
  `(& (+ ,value ,oop/align-padding) ,oop/payload-mask))

(define-form aligned-to-oop? (ptr)
  `(= 0 (& ,ptr ,oop/tag-mask)))

(define-form oop? (word)
  `(aligned-to-oop? ,word))

(define-form immediate? (word)
  `(not (oop? ,word)))

(define-constant target-boolean/true  1)
(define-constant target-boolean/false 0)

(define-function target-boolean (value)
  (if value target-boolean/true target-boolean/false))

(define-form malloc-oops (wordcount)
  `(libc/malloc (words-to-bytes ,wordcount)))

(define-form copy-oops (from to wordcount)
  `(libc/memcpy ,to ,from (words-to-bytes ,wordcount)))

(define-form move-oops (from to wordcount)
  `(libc/memmove ,to ,from (words-to-bytes ,wordcount)))

(define-form size-of-structure (type)
  (structure-field-count (eval type)))

;; the header of heap objects
(eval `(define-structure <header> (,@(when (<= 3 safety-level) (list 'magic-marker)) size flags next type)))

(define-constant size-of-<header> (words-to-bytes (size-of-structure <header>)))

(define-form header-of (arg)
  `(- ,arg ,size-of-<header>))

(let ((marker 233495534)) ; 0xDEADBEE, it's just an easy to recognize token without any meaning
  (define-form valid-header-magic-marker? (header)
    `(= (<header>-magic-marker ,header) ,marker))

  (define-form initialize-header-magic-marker (header)
    `(set (<header>-magic-marker ,header) ,marker)))

(define-constant <header>-flags/used	1)
(define-constant <header>-flags/opaque	2) ; the GC will not look inside opaque objects
(define-constant <header>-flags/mark	4)

(define *subr-registry* ()) ; define-subr collects them here at compile time

;;;
;;;
;;; Actual artifacts that are meant to be level-shifted into the target
;;;
;;;
(compile-begin)

(define k/+done+) ; we need a unique value that k/read cannot ever read from any source file; will be initialized at startup

(define *backtrace-stack*     0)
(define *backtrace-index*     0)

(define-function max (a b)
  (if (> a b) a b))

;;;
;;; libc externs
;;; ----------------------------------------------------------------

(define-constant libc/EOF -1)

;; TODO this unconditionally prefixes every extern with libc/
(define-externs
  abort exit
  malloc free realloc memset memcpy memmove
  stdin stdout stderr
  printf fprintf sprintf snprintf
  strlen strcmp strdup strtoul
  fgetc ungetc fputc
  fopen fdopen fclose fflush fscanf feof)

(define-function libc/flush-streams ()
  (libc/fflush libc/stdout)
  (libc/fflush libc/stderr))

;;;
;;; error handling
;;; ----------------------------------------------------------------

(define k/print) ; forward
(define print-backtrace) ; forward

(define-function die ()
  (libc/fprintf libc/stderr "\nDIE called at depth %d, printing a backtrace to stdout and exiting with exit code 1...\n" *backtrace-index*)
  (libc/flush-streams)
  (print-backtrace)
  (libc/abort))

;; FATAL directly uses the libc printf (i.e. it cannot print maru objects), while
;; K/ERROR goes through the maru printing facility (i.e. must not be called with an .asciz).
(define-function fatal  (fmt)           (libc/fprintf libc/stderr fmt)           (libc/fprintf libc/stderr "\n") (die))
(define-function fatal1 (fmt arg)       (libc/fprintf libc/stderr fmt arg)       (libc/fprintf libc/stderr "\n") (die))
(define-function fatal2 (fmt arg1 arg2) (libc/fprintf libc/stderr fmt arg1 arg2) (libc/fprintf libc/stderr "\n") (die))

;; FIXME it would be nice for K/ERROR to be a function (or at least expand to a breakpoint'able function call),
;; but that would need the compiler to support variable nr of args, or literal lists
(define-form k/error args
  `(let ()
     (libc/printf "\nerror: ")
     ,@(map (lambda (arg)
              ;; string literals are turned into pointers to .asciz, therefore
              ;; we need to print them using libc/printf (or instantiate
              ;; them into Maru objects using new-<string>-from-cstring).
              (if (string? arg)
                  `(libc/printf ,arg)
                  `(k/print ,arg)))
            args)
     (libc/printf "\n")
     (die)))

;;;
;;; GC
;;; ----------------------------------------------------------------

(define gc/quantum              (* 50 1024))
(define gc/frequency            32768)

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

(define-form gc/protect (vars . prog)
  (let ((make-protectors
         (lambda (vars)
           (map (lambda (v) `(gc/push-root (address-of ,v)))
                vars)))
        (make-unprotectors
         (lambda (vars)
           (let ((result ()))
             (while (pair? vars)
               (set result (cons `(gc/pop-root (address-of ,(car vars))) result))
               (set vars (cdr vars)))
             result))))
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

(define-function gc/acquire-new-heap-space (size)
  (let ((ptr (libc/malloc size)))
    (or ptr (fatal "out of memory"))
    (set (<header>-size  ptr) (- size size-of-<header>))
    (set (<header>-flags ptr) 0)
    (set (<header>-next  ptr) ptr)
    (gc/debug (libc/printf "heap growth %p size %d %d/%d\n" ptr size gc/alloc-count gc/frequency))
    (k/assert (aligned-to-oop? ptr) "gc/acquire-new-heap-space: aligned-to-oop? has failed for ptr "ptr)
    ptr))

(define-function gc/initialise ()
  (let ((ptr (gc/acquire-new-heap-space gc/quantum)))
    (set gc/memory-base ptr)
    (set gc/memory-last ptr)))

(define-function gc/push-root (ptr)
  (gc/debug (libc/printf "gc/push-root %d at %p\n" gc/root-count ptr))
  (when (= gc/root-count gc/root-max)
    (let ((new-roots (malloc-oops (set gc/root-max (max 32 (* 2 gc/root-max))))))
      (copy-oops gc/roots new-roots gc/root-count)
      (and gc/roots (libc/free gc/roots))
      (set gc/roots new-roots)))
  (set-oop-at gc/roots gc/root-count ptr)
  (set gc/root-count (+ 1 gc/root-count)))

(define-function gc/pop-root (ptr)
  (gc/debug (libc/printf "gc/pop-root %d at %p\n" gc/root-count ptr))
  (or gc/root-count (fatal "root table underflow"))
  (set gc/root-count (- gc/root-count 1))
  (or (= ptr (oop-at gc/roots gc/root-count))
      (fatal "non-lifo root")))

(define-function gc/grow-heap (size)
  (let ((new-block (gc/acquire-new-heap-space size)))
    (set (<header>-next new-block) (<header>-next gc/memory-last))
    (set (<header>-next gc/memory-last) new-block)))

(define-function gc/object-size (obj)
  (<header>-size (header-of obj)))

(define-function gc/sweep ()
  (gc/debug (libc/printf "sweep\n"))
  (let ((ptr gc/memory-base)
        (nobjs 0)
        (nused 0)
        (nfree 0))
    (while ptr
      (gc/debug (libc/printf "sweep? %d %p + %d\n" (<header>-flags ptr) ptr (<header>-size ptr)))
      (let ((flags (<header>-flags ptr)))
        (if (& flags <header>-flags/mark)
            (let ()
              (safety 3 (and (= 0 (<header>-type ptr)) (fatal1 "gc/sweep: encountered an object with zero type %p" ptr)))
              (set nused (+ nused (<header>-size ptr)))
              (set nobjs (+ nobjs 1))
              (set (<header>-flags ptr) (^ flags <header>-flags/mark)))
          (gc/debug (libc/printf "collect %p size %d\n" ptr (<header>-size ptr)))
          (set nfree (+ nfree (<header>-size ptr)))
          (set (<header>-flags ptr) 0)
          (set (<header>-type ptr) 0)))
      (and (= gc/memory-base (set ptr (<header>-next ptr)))
           (set ptr 0)))
    (set gc/objects-live nobjs)
    (set gc/bytes-used nused)
    (set gc/bytes-free nfree)
    (debug (libc/printf "GC: %d used, %d free, %d allocations\n" nused nfree gc/alloc-count))))

(define-function gc/mark-and-trace (obj)
  (and obj
       (not (immediate? obj))
       (let* ((header (header-of obj))
              (flags  (<header>-flags header)))
         (gc/debug (libc/printf "mark and trace %p flags %d size %d type %d\n" header flags (<header>-size header) (<header>-type header)))
         (safety 3 (or (valid-header-magic-marker? header)  (fatal1 "gc/mark-and-trace: encountered an untagged pointer: %p" obj)))
         (safety 1 (or (& <header>-flags/used flags)      (fatal1 "gc/mark-and-trace: attempt to mark dead object %p" header)))
         (or (& flags <header>-flags/mark)
             (let ()
               (set (<header>-flags header) (| flags <header>-flags/mark))
               (or (& flags <header>-flags/opaque)
                   (let ((index (bytes-to-words (<header>-size header))))
                     (gc/debug (libc/printf "mark %p wordsize %d type %d\n" header index (<header>-type header)))
                     (safety 2 (or (not (= 0 (<header>-type header))) (fatal1 "gc/mark-and-trace: encountered an object with zero type %p" header)))
                     (while index
                       (set index (- index 1))
                       (gc/debug (libc/printf "@%d %p\n" index (header-of (oop-at obj index))))
                       (gc/mark-and-trace (oop-at obj index))))))))))

(define-function gc/collect ()
  (gc/debug
    (or (& 1023 (set gc/collection-count (+ gc/collection-count 1)))
        (libc/fprintf libc/stderr "%d collections\n" gc/collection-count 1)))
  (let ((i 0))
    (while (< i gc/root-count)
      (gc/debug (let ((root (oop-at gc/roots i))) (libc/printf "mark gc root %d : %p -> %p\n" i root (header-of (oop-at root 0)))))
      (gc/mark-and-trace (oop-at (oop-at gc/roots i) 0))
      (set i (+ 1 i))))
  (gc/sweep)
  (set gc/alloc-count 0))

(define-function gc/allocate (requested-size)
  (gc/debug (libc/printf "gc/allocate %d\n" requested-size))
  (set requested-size (oop/align requested-size)) ; KLUDGE this really only aligns the size, not the returned pointer. works for now.
  (and (= gc/alloc-count gc/frequency)
       (gc/collect))
  (let* ((first (<header>-next gc/memory-last))
         (chunk first)
         (total-size (+ requested-size size-of-<header>)))
    (while 1
      (while
        (let ()
          (gc/debug (libc/printf "alloc? %d %p %p [%p] %d >= %d %d\n" (<header>-flags chunk) chunk (<header>-next chunk) first (<header>-size chunk) requested-size (<= requested-size (<header>-size chunk))))
          (when (= 0 (<header>-flags chunk)) ;; i.e. free chunk
            (let ((chunk-size (<header>-size chunk)))
              (while (and (= 0 (<header>-flags (<header>-next chunk)))
                          (= (<header>-next chunk) (+ chunk (+ size-of-<header> chunk-size))))
                ;; merge all consecutive free chunks
                (let ((next (<header>-next chunk)))
                  (set (<header>-next chunk) (<header>-next next))
                  (set chunk-size (set (<header>-size chunk) (+ chunk-size (+ size-of-<header> (<header>-size next)))))
                  (and (= next gc/memory-last) (set gc/memory-last chunk))))
              ;; TODO ? total-size includes the header while chunk-size is only the size of the payload space
              (when (or (< total-size chunk-size) ; we'll split this chunk
                        (= requested-size chunk-size)) ; we'll use the entire chunk
                (gc/debug (libc/printf "chunk-size %d\n" chunk-size))
                (when (> chunk-size total-size)
                  (let ((split (+ chunk total-size)))
                    (gc/debug (libc/printf "split %d: %p + %d -> %p + %d\n" chunk-size chunk requested-size split (- chunk-size total-size)))
                    (set (<header>-size  split) (- chunk-size total-size))
                    (set (<header>-flags split) 0)
                    (set (<header>-next  split) (<header>-next chunk))
                    (set (<header>-size  chunk) requested-size)
                    (set (<header>-next  chunk) split)
                    (set chunk-size requested-size)))
                (set (<header>-flags chunk) <header>-flags/used)
                (set gc/memory-last chunk)
                (gc/debug (libc/printf "alloc chunk %p\n" chunk))
                (let ((obj (+ chunk size-of-<header>)))
                  (libc/memset obj 0 chunk-size)
                  (set gc/alloc-count (+ gc/alloc-count 1))
                  (safety 4 (k/assert (= (gc/object-size obj) requested-size) "gc/allocate: was about to return with an object whose size in the header is not equal to the requested size"))
                  (safety 4 (k/assert (& <header>-flags/used (<header>-flags (header-of obj))) "gc/allocate: was about to return with an object whose USED flag is unset"))
                  (safety 3 (initialize-header-magic-marker (header-of obj)))
                  (gc/debug (libc/printf "gc/allocate: returning with %p (%p), size %d\n" (header-of obj) obj (gc/object-size obj)))
                  (return obj)))))
          (!= first (set chunk (<header>-next chunk)))))
      (gc/grow-heap (max (+ size-of-<header> requested-size) gc/quantum)))))

(define-function gc/allocate-opaque (size)
  (let ((obj (gc/allocate size)))
    (set (<header>-flags (header-of obj)) (+ <header>-flags/used <header>-flags/opaque))
    obj))

;;;
;;; types and their kernel accessors
;;; ----------------------------------------------------------------
;;;
;;; types are represented at runtime as integers upfrom 0.
;;; <undefined> doesn't necessarily need to be denoted by zero.
;;; the subr's here in eval.l encode/implement the behavior of the primitive types.

(define-form bootstrap-types type-names
  `(let ()
     ,@(map (lambda (type-name)
              `(define-constant ,type-name ,(eval type-name)))
            type-names)))

;; level-shift the ids of some types that we will need to denote in the target
(bootstrap-types
 <undefined>
 <target-vm-pointer>
 <data>
 <long>
 <string>
 <symbol>
 <pair>
 <array>
 <expr>
 <form>
 <fixed>
 <subr>
 <variable>
 <env>
 <context>
 <module>)

(define-form %get/type ()
  `(define-function get/type (word)
     (cond
       ((not word)	<undefined>)
       ((oop? word)	(let ((header (header-of word)))
                          (safety 3 (or (valid-header-magic-marker? header) (fatal1 "get/type: encountered an untagged pointer: %p" word)))
                          (safety 1 (or (& <header>-flags/used (<header>-flags header)) (fatal1 "get/type: attempt to access dead object: %p" word)))
                          (<header>-type header)))
       ((immediate? word) (cond
                            ,@(let ((conds ()))
                                (for (type 0 (array-length %immediate-type/tag-values))
                                  (when (immediate-type? type)
                                    (let* ((tag-value (immediate-type/tag-value type))
                                           (tag-width (immediate-type/tag-width type))
                                           (tag-mask  (^ (- (<< 1 tag-width)) -1))) ; TODO this should use bitwise not instead of xor
                                      (push conds `((= ,tag-value (& word ,tag-mask)) ,type)))))
                                conds)
                            (else (fatal1 "get/type: encountered an unidentifiable immediate: {%p}" word))))
       (else (fatal1 "get/type: encountered something unidentifiable: {%p}" word)))))

(%get/type)

(define-form is (type word)
  `(= ,type (get/type ,word)))

(define-function %type-check-failed (exp act)
  (fatal2 "type error: expected %d, got %d" exp act))

;; "one of the reasons for having all accesses to object fields go through get() and set() was to make it ridiculously easy to add read and write barriers"
(define-form get (type field object)
  `(let ((__obj__ ,object))
     (safety 2 (let ((t (get/type __obj__))) (or (= ,type t) (%type-check-failed ,type t))))
     (,(concat-symbol (concat-symbol type '-) field) __obj__)))

(define-form put (type field object value)
  `(let ((__obj__ ,object))
     (safety 2 (let ((t (get/type __obj__))) (or (= ,type t) (%type-check-failed ,type t))))
     (set (,(concat-symbol (concat-symbol type '-) field) __obj__) ,value)))

;; shorthands (and optimizations)
(define-form get/globals	()		`(get <variable> value (get <module> globals *module*)))
(define-form get/globals*	(obj)		`(get <variable> value (get <module> globals ,obj)))

(define-form is/long		(obj)		`(is <long> ,obj))
(define-form is/pair		(obj)		`(is <pair> ,obj))
(if (immediate-type? <long>)
    (define-form get/long	(obj)		`(>> ,obj ,(immediate-type/tag-width <long>)))
    (define-form get/long	(obj)		(if (< safety-level 3)		`(oop-at ,obj ,(structure-field-index <long> '_bits))		`(get <long> _bits ,obj))))
(define-form get/head		(obj)		(if (< safety-level 3)		`(oop-at ,obj ,(structure-field-index <pair> 'head))		`(get <pair> head ,obj)))
(define-form put/head		(obj val)	(if (< safety-level 3)	    `(set-oop-at ,obj ,(structure-field-index <pair> 'head) ,val)	`(put <pair> head ,obj ,val)))
(define-form get/tail		(obj)		(if (< safety-level 3)		`(oop-at ,obj ,(structure-field-index <pair> 'tail))		`(get <pair> tail ,obj)))
(define-form put/tail		(obj val)	(if (< safety-level 3)	    `(set-oop-at ,obj ,(structure-field-index <pair> 'tail) ,val)	`(put <pair> tail ,obj ,val)))

(define-form is/tptr		(obj)		`(is <target-vm-pointer> ,obj))
(define-form get/tptr		(obj)		`(get <target-vm-pointer> _bits ,obj))

(define-form get/string		(obj)		`(get <string> _bits ,obj))
(define-form get/symbol		(obj)		`(get <symbol> _bits ,obj))

(define-form get/variable-value	(var)		`(get <variable> value
                                                      ,(if (string? var)
                                                           `(k/env/lookup-variable (get/globals) (intern ,var))
                                                         var)))

(define-form put/variable-value	(var val)	`(put <variable> value
                                                      ,(if (string? var)
                                                           `(k/env/lookup-variable (get/globals) (intern ,var))
                                                         var)
                                                      ,val))

(define-function k/car (list)
  (when list
    (k/assert (is/pair list) "k/car called on non-list: " list)
    (get/head list)))

(define-function k/cdr (list)
  (when list
    (k/assert (is/pair list) "k/cdr called on non-list: " list)
    (get/tail list)))

(define-function k/caar		(list)		(k/car (k/car list)))
(define-function k/cadr		(list)		(k/car (k/cdr list)))
(define-function k/cddr		(list)		(k/cdr (k/cdr list)))
(define-function k/caddr	(list)		(k/car (k/cdr (k/cdr list))))
(define-function k/cadddr	(list)		(k/car (k/cdr (k/cdr (k/cdr list)))))

(define-function new-object (type wordsize)
  (safety 1 (k/assert (not (= 0 type)) "new-object: called with zero type"))
  (let* ((obj (gc/allocate (words-to-bytes wordsize)))
         (header (header-of obj)))
    (k/assert (aligned-to-oop? obj) "new-object: gc/allocate returned not aligned-to-oop? {%p}\n" obj)
    (set (<header>-type header) type)
    (debug (libc/printf "new-object returning %p\n" obj))
    obj))

(define-function new-object/opaque (type bytesize)
  (safety 1 (k/assert (not (= 0 type)) "new-object/opaque: called with zero type"))
  (let* ((obj (gc/allocate-opaque bytesize))
         (header (header-of obj)))
    (set (<header>-type header) type)
    obj))

(define-form %new-<long> ()
  (if (immediate-type? <long>)
      `(define-form new-<long> (bits)
         ;; TODO fix nested backquotes finally
         (list '+ (list '<< bits ,(immediate-type/tag-width <long>))
               ,(immediate-type/tag-value <long>)))
    `(define-function new-<long> (bits)
       (let ((obj (new-object/opaque <long> (words-to-bytes (size-of-structure <long>)))))
         (set (<long>-_bits obj) bits)
         obj))))

(%new-<long>)

(define-function new-<target-vm-pointer> (bits)
  (let ((obj (new-object/opaque <target-vm-pointer> (words-to-bytes (size-of-structure <target-vm-pointer>)))))
    (set (<target-vm-pointer>-_bits obj) bits)
    obj))

(define-function new-<pair> (head tail)
  (let ((obj (new-object <pair> (size-of-structure <pair>))))
    (set (<pair>-head obj) head)
    (set (<pair>-tail obj) tail)
    obj))

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

(define-function k/concat-list (head tail)
  (if (is/pair head)
      (let ()
        (set tail (k/concat-list (get/tail head) tail))
        (gc/protect (tail)
          (new-<pair> (get/head head) tail)))
    tail))

;;;
;;; global state of the VM
;;; ----------------------------------------------------------------

(define *arg/verbose*		0)
(define *arg/optimised*		0)

;; Some of the state of the Maru VM being implemented needs to be
;; captured/known by the code implementing it in the target VM.
;; Only the first one of these is essential: *module*, the rest could
;; be looked up each time; i.e. they're just optimization or debug helpers.
(define *module*)

;; optimization: we cache these definitions from the env of the Maru VM
;; to avoid looking them up a gazillion times.
(define var/*expanders*)
(define var/*encoders*)
(define var/*evaluators*)
(define var/*applicators*)
(define var/*input*)

(define symbol/t)
(define symbol/dot)
(define symbol/define)
(define symbol/set)
(define symbol/quote)
(define symbol/quasiquote)
(define symbol/unquote)
(define symbol/unquote_splicing)

(define fixed-subr/quote)
(define fixed-subr/lambda)
(define fixed-subr/let)
(define fixed-subr/define)
(define fixed-subr/set)

;;;
;;; instantiation
;;; ----------------------------------------------------------------

(define-function new-<string>-of-length (len)
  (let ((str (new-object <string> (size-of-structure <string>))))
    (gc/protect (str)
      (set (<string>-size  str) (new-<long> len))
      (set (<string>-_bits str) (new-object/opaque <data> (+ len 1))) ; +1 is for the terminal zero
      str)))

(define-function new-<string>-from-cstring (cstr)
  (let ((len (libc/strlen cstr)))
    (let ((obj (new-<string>-of-length len))) ; also deals with the cstring terminal zero
      (libc/memcpy (<string>-_bits obj) cstr len)
      obj)))

(define-function new-<symbol> (cstr)
  ;; NOTE: strdup is malloc; if we assume that symbols never get collected, then we can allocate an opaque object for symbols.
  (let ((obj (new-object/opaque <symbol> (words-to-bytes (size-of-structure <symbol>)))))
    (set (<symbol>-_bits obj) (libc/strdup cstr))
    obj))

(define-function new-<array> (size)
  (let ((cap (or size 1))
        (arr (new-object <array> (size-of-structure <array>))))
    (gc/protect (arr)
      (set (<array>-size arr)   (new-<long> size))
      (set (<array>-_bits arr)  (new-object <data> cap))
      arr)))

(define-function new-<expr> (defn ctx)
  (let ((obj (new-object <expr> (size-of-structure <expr>))))
    (set (<expr>-defn obj) defn)
    (set (<expr>-ctx  obj) ctx )
    obj))

(define-function new-<form> (fn sym)
  (let ((obj (new-object <form> (size-of-structure <form>))))
    (gc/protect (obj)
      (set (<form>-function obj) fn)
      (set (<form>-symbol   obj) sym)
      obj)))

(define-function new-<fixed> (fn)
  (let ((obj (new-object <fixed> (size-of-structure <fixed>))))
    (gc/protect (obj)
      (set (<fixed>-function obj) fn)
      obj)))

(define-function new-<subr> (_imp _name)
  (let ((obj (new-object/opaque <subr> (words-to-bytes (size-of-structure <subr>)))))
    (gc/protect (obj)
      (set (<subr>-_imp  obj) _imp )
      (set (<subr>-_name obj) _name)
      obj)))

(define-function new-<variable> (name value env index)
  (let ((obj (new-object <variable> (size-of-structure <variable>))))
    (gc/protect (obj)
      (set (<variable>-name  obj) name)
      (set (<variable>-value obj) value)
      (set (<variable>-env   obj) env)
      (set (<variable>-index obj) (new-<long> index))
      obj)))

(define-function new-<env> (parent level offset)
  (let ((obj (new-object <env> (size-of-structure <env>))))
    (gc/protect (obj)
      (set (<env>-parent   obj) parent)
      (set (<env>-level    obj) (new-<long> (if parent (+ (get/long (get <env> level parent)) level) 0)))
      (set (<env>-offset   obj) (new-<long> offset))
      (set (<env>-bindings obj) (new-<array> 0))
      obj)))

(define-function new-base-<context> (home caller env)
  (let ((obj (new-object <context> (size-of-structure <context>))))
    (gc/protect (obj)
      (set (<context>-home     obj) home)
      (set (<context>-env      obj) env)
      (set (<context>-bindings obj) (new-<array> 0))
      obj)))

;; TODO see the relevant part of eval.c for the comment: fix escape analysis for nested lambdas with free variables
;; with this version below the following breaks:
;; (define compose (lambda (a b c)
;;                  (lambda (x y)
;;                    (list a b c x y))))
;; ((compose 1 2 3) 42 43)
;;
;; (define-function new-<context> (home caller env)
;;   (let ((obj ()))
;;     (if (and caller (set obj (get <context> callee caller)))
;; 	(let ()
;; 	  (put <context> home obj home)
;; 	  (put <context> env  obj env))
;;       (set obj (new-base-<context> home caller env))
;;       (and caller (put <context> callee caller obj)))
;;     obj))

(define-function new-<context> (home caller env)
  (let ((obj (new-base-<context> home caller env)))
    (and caller (put <context> callee caller obj))
    obj))

;;;
;;; env
;;; ----------------------------------------------------------------

(define-function global-variable? (var)
  (let ((env (get <variable> env var)))
    (and env (= 0 (get/long (get <env> level env))))))

(define-function k/env/lookup-variable (env name)
  (safety 1 (k/assert (is <env> env)     "k/env/lookup-variable: env is not an <env>: "env))
  (safety 1 (k/assert (is <symbol> name) "k/env/lookup-variable: name is not a <symbol>: "name))
  (while env
    (let* ((bindings (get <env> bindings env))
           (index    (k/array-length bindings))
           (vars     (get <array> _bits bindings))) ; KLUDGE? early optimization?
      (while (<= 0 (set index (- index 1)))
        (let ((var (oop-at vars index)))
          (and (= name (get <variable> name var))
               (return var)))))
    (set env (get <env> parent env))))

(define-function k/env/lookup-variable-or-die (env name)
  (let ((var (k/env/lookup-variable env name)))
    (or (and var (is <variable> var)) (fatal1 "k/env/lookup-variable-or-die failed for %s" (get/symbol name)))
    var))

(define-function k/env/variable-value (env name)
  (let ((var (k/env/lookup-variable env name)))
    (if var
        (get <variable> value var)
      (fatal1 "undefined variable: %s" (get/symbol name)))))

(define-function k/env/ensure-variable (env name)
  (safety 1 (k/assert (is <env> env)		"k/env/ensure-variable: env arg is not of type env: "env))
  (safety 1 (k/assert (is <symbol> name)	"k/env/ensure-variable: name arg is not of type symbol: "name))
  (let* ((bindings (get <env> bindings env))
         (index (k/array-length bindings)))
    (while (<= 0 (set index (- index 1)))
      (let ((var (k/array-at bindings index)))
        (and (= name (get <variable> name var))
             (return var))))
    (let* ((off (get/long (get <env> offset env)))
           (var (new-<variable> name () env off)))
      (gc/protect (var)
        (put <env> offset env (new-<long> (+ off 1)))
        (k/array-append bindings var)))))

(define-function k/env/define (env name value)
  (safety 1 (k/assert (is <env> env) "k/env/define: env arg is not of type env: "env))
  (safety 1 (k/assert (is <symbol> name) "k/env/define: name arg is not of type symbol: "name))
  (debug (libc/printf "k/env/define called, name is %s\n" (get/symbol name)))
  (let ((var (k/env/ensure-variable env name)))
    (put <variable> value var value)
    var))

;;;
;;; reader
;;; ----------------------------------------------------------------

(define-function is_blank (c)   (or      ( = ?   c)                     ; sp
                                         ( = ?\t c)                     ; ht
                                         ( = ?\n c)                     ; nl
                                         ( = ?\v c)                     ; vt
                                         ( = ?\f c)                     ; ff
                                         ( = ?\r c)))                   ; cr

(define-function is_digit10 (c)     (and (<= ?0  c) (<= c ?9)))         ; 0 1 2 3 4 5 6 7 8 9

(define-function is_digit16 (c) (or (and (<= ?0  c) (<= c ?9))          ; 0 1 2 3 4 5 6 7 8 9
                                    (and (<= ?a  c) (<= c ?f))          ; a b c d e f
                                    (and (<= ?A  c) (<= c ?F))))        ; A B C D E F

(define-function is_alpha (c)   (or (and (<= ?a  c) (<= c ?z))          ; a b c d e f g h i j k l m n o p q r s t u v w x y z
                                    (and (<= ?A  c) (<= c ?Z))))        ; A B C D E F G H I J K L M N O P Q R S T U V W X Y Z

(define-function is_letter (c)  (or      ( = ?!  c)                     ; !
                                    (and (<= ?#  c) (<= c ?&))          ; # $ % &
                                    (and (<= ?*  c) (<= c ?/))          ; * + , - . /
                                         ( = ?:  c)                     ; :
                                    (and (<= ?<  c) (<= c ?Z))          ; < = > ?  @ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
                                         ( = ?\\ c)                     ; \
                                         ( = ?^  c)                     ; ^
                                         ( = ?_  c)                     ; _
                                    (and (<= ?a  c) (<= c ?z))          ; a b c d e f g h i j k l m n o p q r s t u v w x y z
                                         ( = ?|  c)                     ; |
                                         ( = ?~  c)))                   ; ~

(define-structure <buffer> (contents size position))

(define-function new_buffer ()
  (let ((buf (libc/malloc (words-to-bytes (size-of-structure <buffer>)))))
    (set (<buffer>-contents buf) (libc/malloc 32))
    (set (<buffer>-size     buf) 32)
    (set (<buffer>-position buf) 0)
    buf))

(define-function buffer_delete (buf)
  (libc/free (<buffer>-contents buf))
  (libc/free buf))

(define-function buffer_grow (buf)
  (let* ((size     (<buffer>-size buf))
         (contents (libc/malloc (* 2 size))))
    (libc/memcpy contents (<buffer>-contents buf) size)
    (libc/free (<buffer>-contents buf))
    (set (<buffer>-contents buf) contents)
    (set (<buffer>-size buf) (* 2 size))))

(define-function buffer_append (buf c)
  (and (= (<buffer>-position buf) (<buffer>-size buf))
       (buffer_grow buf))
  (let ((posn (<buffer>-position buf)))
    (set-string-at (<buffer>-contents buf) posn c)
    (set (<buffer>-position buf) (+ 1 posn))))

(define-function buffer_append_all (buf s)
  (let ((i 0)
        (c 0))
    (while (set c (string-at s i))
      (buffer_append buf c)
      (set i (+ 1 i)))))

(define-function buffer_contents (buf)
  (buffer_append buf 0)
  (set (<buffer>-position buf) (- (<buffer>-position buf) 1))
  (<buffer>-contents buf))

(define-function intern* (cstr module)
  (safety 1 (k/assert (is <module> module) "intern called with not a module " module))
  ;; deal with ?: syntax for denoting modules
  (let ((len (libc/strlen cstr))
        (idx 0))
    (while (< idx len)
      (when (= ?: (string-at cstr idx))
        (let ((module-name (libc/malloc (+ 1 idx))))
          (libc/memcpy module-name cstr idx)
          (set (string-at module-name idx) 0)
          (let ((submod (k/env/variable-value (get/globals* module) (intern* module-name module))))
            (unless (is <module> submod)
              (fatal2 "intern: '%s' is found, but it's not a module while interning %s" module-name cstr))
            (libc/free module-name)
            (return (intern* (+ 1 (+ cstr idx)) submod)))))
      (set idx (+ 1 idx))))
  ;; no module is denoted in cstr (anymore); it's just a symbol to be at this point
  (let ((symbols (<module>-symbols module)))
    (let ((lo 0)
          (hi (- (k/array-length symbols) 1)))
    (while (<= lo hi)
      (let* ((mid	(/ (+ lo hi) 2))
             (candidate	(k/array-at symbols mid))
             (c		(libc/strcmp cstr (get/symbol candidate))))
        (cond
          ((< c 0)	(set hi (- mid 1)))
          ((> c 0)	(set lo (+ mid 1)))
          (else		(return candidate)))))
    (debug (libc/printf "interning %s into module {%p}\n" cstr module))
    (gc/let* ((sym (new-<symbol> cstr)))
      (k/array-insert symbols lo sym)
      sym))))

(define-function intern (cstr)
  (intern* cstr *module*))

(define-function is_octal (c)           (and (<= ?0 c) (<= c ?7)))

(define-function is_hexadecimal (c)     (or (and (<= ?0 c) (<= c ?9))
                                            (and (<= ?a c) (<= c ?f))
                                            (and (<= ?A c) (<= c ?F))))

(define-function digit_value (c)
  (cond
    ((and (<= ?0 c) (<= c ?9))  (- c ?0))
    ((and (<= ?a c) (<= c ?z))  (- c (- ?a 10)))
    ((and (<= ?A c) (<= c ?Z))  (- c (- ?A 10)))
    (else                       (fatal1 "illegal digit in character escape: %c" c))))

(define k/read) ; forward

(define-function read_char (c stream)
  (if (= ?\\ c)
      (let ()
        (set c (libc/fgetc stream))
        (cond
          ((= c ?a)                     ?\a)
          ((= c ?b)                     ?\b)
          ((= c ?f)                     ?\f)
          ((= c ?n)                     ?\n)
          ((= c ?r)                     ?\r)
          ((= c ?t)                     ?\t)
          ((= c ?v)                     ?\v)
          ((= c ?u)                     (let ((a (libc/fgetc stream))
                                              (b (libc/fgetc stream))
                                              (c (libc/fgetc stream))
                                              (d (libc/fgetc stream)))
                                          (or (and (is_hexadecimal a)
                                                   (is_hexadecimal b)
                                                   (is_hexadecimal c)
                                                   (is_hexadecimal d))
                                              (k/error "illegal character escape"))
                                          (+ (<< (digit_value a) 24)
                                             (+ (<< (digit_value b) 16)
                                                (+ (<< (digit_value c)  8)
                                                   (digit_value d))))))
          ((= c ?x)                     (let ((x 0))
                                          (if (is_hexadecimal (set c (libc/fgetc stream)))
                                              (let ()
                                                (set x (digit_value c))
                                                (if (is_hexadecimal (set c (libc/fgetc stream)))
                                                    (let ()
                                                      (set x (+ (* x 16) (digit_value c)))
                                                      (set c (libc/fgetc stream)))
                                                  (k/error "illegal character escape"))))
                                          (libc/ungetc c stream)
                                          x))
          ((and (<= ?0 c) (<= c ?7))    (let ((x (digit_value c)))
                                          (if (is_octal (set c (libc/fgetc stream)))
                                              (let ()
                                                (set x (+ (* x 8) (digit_value c)))
                                                (if (is_octal (set c (libc/fgetc stream)))
                                                    (let ()
                                                      (set x (+ (* x 8) (digit_value c)))
                                                      (set c (libc/fgetc stream)))
                                                  (k/error "illegal character escape"))))
                                          (libc/ungetc c stream)
                                          x))
          (else                 (if (or (is_alpha c) (is_digit10 c))
                                    (fatal1 "illegal character escape: \\%c" c)
                                  c))))
    c))

(define-function read_number (c stream)
  (let ((buf (new_buffer))
        (neg (= ?- c)))
    (or neg (buffer_append buf c))
    (while (is_digit10 (set c (libc/fgetc stream))) (buffer_append buf c))
    (and (= ?x c) (= 1 (<buffer>-position buf))
         (let ()
           (buffer_append buf c)
           (while (is_digit16 (set c (libc/fgetc stream))) (buffer_append buf c))))
    (libc/ungetc c stream)
    (buffer_append buf 0)
    (let ((result (libc/strtoul (<buffer>-contents buf) 0 0)))
      (buffer_delete buf)
      (new-<long> (if neg (- result) result)))))

(define-function read_symbol (c stream)
  (let ((buf (new_buffer)))
    (while (or (is_letter c) (is_digit10 c))
      (buffer_append buf c)
      (set c (libc/fgetc stream)))
    (libc/ungetc c stream)
    (buffer_append buf 0)
    (let ((result (intern (<buffer>-contents buf))))
      (buffer_delete buf)
      result)))

(define-function read_string (c stream)
  (let ((buf (new_buffer)))
    (while (!= ?\" (set c (libc/fgetc stream)))
      (set c (read_char c stream))
      (when (= libc/EOF c)
        (k/error "unterminated string literal"))
      (buffer_append buf c))
    (buffer_append buf 0)
    (let ((result (new-<string>-from-cstring (<buffer>-contents buf))))
      (buffer_delete buf)
      result)))

(define-function read_list (delim stream)
  (let* ((head (new-<pair> () ()))
         (tail head)
         (elt  ()))
    (gc/protect (head elt)
      (while (and (!= k/+done+ (set elt (k/read stream)))
                  (!= symbol/dot elt))
        (set elt (new-<pair> elt ()))
        (set tail (put/tail tail elt)))
      (and (= symbol/dot elt) (put/tail tail (k/read stream))))
    (let ((c (libc/fgetc stream)))
      (if (= delim c)
          (get/tail head)
        (fatal1 "missing closing '%c' delimiter while reading list" delim)))))

(define-function read_quote (prefix stream)
  (let ((qobj (k/read stream)))
    (when (= k/+done+ qobj)
      (k/error "EOF while reading quoted literal"))
    (gc/protect (qobj)
      (set qobj (new-<pair> qobj ()))
      (set qobj (new-<pair> prefix qobj))
      qobj)))

(set k/read (lambda (stream)
  (while 1
    (let ((c (libc/fgetc stream)))
      (cond
        ((is_blank c)   ())
        ((= ?? c)       (return (new-<long> (read_char (libc/fgetc stream) stream))))
        ((= ?- c)       (return (if (is_digit10 (libc/ungetc (libc/fgetc stream) stream))
                                    (read_number c stream)
                                    (read_symbol c stream))))
        ((= ?\' c)      (return (read_quote symbol/quote stream)))
        ((= ?\` c)      (return (read_quote symbol/quasiquote stream)))
        ((= ?\, c)      (return (let ((d (libc/fgetc stream)))
                                  (if (= ?@ d)
                                      (read_quote symbol/unquote_splicing stream)
                                    (libc/ungetc d stream)
                                    (read_quote symbol/unquote stream)))))
        ((is_letter c)  (return (read_symbol c stream)))
        ((= ?\( c)      (return (read_list ?\) stream)))        ((= ?\) c)      (return (let () (libc/ungetc c stream) k/+done+)))
        ((= ?\[ c)      (return (read_list ?\] stream)))        ((= ?\] c)      (return (let () (libc/ungetc c stream) k/+done+)))
        ((= ?\{ c)      (return (read_list ?\} stream)))        ((= ?\} c)      (return (let () (libc/ungetc c stream) k/+done+)))
        ((is_digit10 c) (return (read_number c stream)))
        ((= ?\; c)      (while (and (!= ?\n (set c (libc/fgetc stream)))
                                    (!= ?\r c)
                                    (!= libc/EOF c))))
        ((= ?\" c)      (return (read_string c stream)))
        ((= c libc/EOF) (if (libc/feof stream)
                            (return k/+done+)
                          (fatal "error while reading from libc stream")))
        (else           (fatal1 "illegal character: %c" c))))))
)
;;;
;;; printer
;;; ----------------------------------------------------------------

(define-function do_print (obj storing)
  ;; NOTE: be prepared to handle uninitialized objects!
  (debug/identities (libc/printf "{%p}" obj))
  (let ((type (get/type obj)))
    (cond
      ((= type <undefined>)     (libc/printf "()"))
      ((= type <long>)          (libc/printf "%d" (get/long obj)))
      ((= type <string>)        (let ((bits (get/string obj)))
                                  (if (not storing)
                                      (libc/printf "%s" bits)
                                    (let ((i 0)
                                          (c 0))
                                      (libc/printf "\"")
                                      (while (set c (string-at bits i))
                                        (if (and (<= 32 c) (<= c 126))
                                            (cond
                                              ((= c ?\")        (libc/printf "\\\""))
                                              ((= c ?\\)        (libc/printf "\\\\"))
                                              (else             (libc/printf "%c" c)))
                                          (libc/printf "\\%03o" c))
                                        (set i (+ 1 i)))
                                      (libc/printf "\"")))))
      ((= type <symbol>)        (libc/printf "%s" (get/symbol obj)))
      ((= type <pair>)          (let ()
                                  (libc/printf "(")
                                  (while (is/pair obj)
                                    (do_print (get/head obj) storing)
                                    (and (is/pair (set obj (get/tail obj)))
                                         (libc/printf " ")))
                                  (and obj
                                       (let ()
                                         (libc/printf " . ")
                                         (do_print obj storing)))
                                  (libc/printf ")")))
      ((= type <array>)         (let ((len (k/array-length obj)))
                                  (libc/printf "Array(")
                                  (for (i 0 len)
                                    (and i (libc/printf " "))
                                    (do_print (k/array-at obj i) storing))
                                  (libc/printf ")")))
      ((= type <expr>)          (let ()
                                  (libc/printf "Expr<")
                                  (do_print (k/cadr (get <expr> defn obj)) storing)
                                  (libc/printf ">")))
      ((= type <form>)          (let ()
                                  (libc/printf "Form<")
                                  (do_print (get <form> function obj) storing)
                                  (libc/printf ",")
                                  (do_print (get <form> symbol   obj) storing)
                                  (libc/printf ">")))
      ((= type <fixed>)         (let ()
                                  (libc/printf "Fixed<")
                                  (do_print (get <fixed> function obj) storing)
                                  (libc/printf ">")))
      ((= type <subr>)          (libc/printf "Subr<%s>" (get <subr> _name obj)))
      ((= type <variable>)      (let ((env (get <variable> env obj)))
                                  (do_print (get <variable> name obj) storing)
                                  (when env
                                    (libc/printf ".")
                                    (do_print (get <env> level env) storing)
                                    (libc/printf "+")
                                    (do_print (get <variable> index obj) storing))))
      ((= type <env>)           (let ((level (get <env> level obj))
                                      (bindings (get <env> bindings obj)))
                                  (if (and level bindings)
                                      (libc/printf "Env<%d,%d>" (get/long level) (k/array-length bindings))
                                      (libc/printf "Env<>"))))
      ((= type <context>)       (let ()
                                  (libc/printf "Context<>")))
      (else                     (libc/printf "<type:%d>" type)))))

(set k/print (lambda (obj) (do_print obj target-boolean/false)))
(define-function k/println	(obj) (do_print obj target-boolean/false) (libc/printf "\n"))

(define-function k/dump		(obj) (do_print obj target-boolean/true))
(define-function k/dumpln	(obj) (do_print obj target-boolean/true) (libc/printf "\n"))

(set print-backtrace
  (lambda ()
    (let ((i *backtrace-index*))
      (while (<= 0 (set i (- i 1)))
        (libc/printf "%3d: " i)
        (k/dumpln (k/array-at *backtrace-stack* i))
        (libc/flush-streams)))))

;;; ----------------------------------------------------------------

(define k/eval) ; forward

(define-function new-<module> ()
  (gc/let* ((module (new-object <module> (words-to-bytes (size-of-structure <module>))))
            (env    (new-<env> () 0 0)))
    (set (<module>-symbols module)	(new-<array> 0))
    (set (<module>-globals module)	(k/env/define env (intern* "*globals*" module) env))
    module))

(define-function k/apply-expr (fun arguments ctx)
  (and (< 2 *arg/verbose*) (let () (libc/printf "  A  ")  (k/dump fun)  (libc/printf " ")  (k/dump arguments) (libc/printf " ")  (k/dumpln ctx) (libc/flush-streams)))
  (let* ((defn    (get <expr> defn fun))
         (env     (get/head defn))
         (formals (get/head (get/tail defn))))
    (set ctx (new-<context> (get <expr> ctx fun) ctx env))
    (gc/protect (ctx)
      (let ((locals (get <context> bindings ctx))
            (args   arguments))
        (while (is/pair formals)
          (or (is/pair args) (k/error "too few arguments for "fun": "arguments))
          (k/set-array-at locals (get/long (get <variable> index (get/head formals))) (get/head args))
          (set formals (get/tail formals))
          (set args    (get/tail args)))
        (and (is <variable> formals)    ; which means it has dotted rest args
             (let ()
               (k/set-array-at locals (get/long (get <variable> index formals)) args)
               (set args ())))
        (and args (k/error "too many arguments for "fun": "arguments))
        ;; execute the body
        (gc/let* ((prog (get/tail (get/tail defn)))
                  (result ()))
          (while (is/pair prog)
            (set result (k/eval (get/head prog) ctx))
            (set prog (get/tail prog)))
          (and (get <env> stable env)
               (put <context> callee ctx ()))
          result)))))

(define-function k/apply (fun arguments ctx)
  ;;(libc/printf "  %02d " *backtrace-index*) (k/dumpln fun)
  (debug (libc/printf "k/apply, function ") (k/dump fun) (libc/printf ", arguments: ") (k/dump arguments) (libc/printf "\n"))
  (k/assert fun "k/apply: fun is nil")
  (let ((type (get/type fun)))
    (cond
      ((= type <expr>)		(k/apply-expr fun arguments ctx))
      ((= type <fixed>)		(k/apply (get <fixed> function fun) arguments ctx))
      ((= type <subr>)		((get <subr> _imp fun) arguments ctx))
      (else			(let ((ap (k/array-at (get/variable-value var/*applicators*) (get/type fun))))
				  (if ap
				      (let ((args arguments))
					(gc/protect (args)
					  (set args (new-<pair> fun args))
					  (k/apply ap args ctx)))
				    (k/error "cannot apply: " fun)))))))

;;; ----------------------------------------------------------------

(define exlist) ; forward

(define-function k/expand (exp env)
  (debug (libc/printf "k/expand, exp ") (k/dump exp) (libc/printf ", env ") (k/dump env) (libc/printf "\n"))
  (cond
    ((is/pair exp)
     (let ((head (k/expand (get/head exp) env)))
       (gc/push-root (address-of head))
       (when (is <symbol> head)
         (let ((val (k/env/lookup-variable env head)))
           (and (is <variable> val) (set val (get <variable> value val)))
           (and (is <form> val)
                (let ((fn (get <form> function val)))
                  (and fn
                       (let ((args (new-<pair> env (get/tail exp))))
                         (gc/protect (args)
                           (set head (k/apply fn args ()))
                           (set head (k/expand head env)))
                         (gc/pop-root (address-of head))
                         (return head)))))))
       (let ((tail (get/tail exp)))
         (gc/push-root (address-of tail))
         (or (= head symbol/quote) (set tail (exlist tail env)))
         ;; convert set forms: (set (foo a b c) new-value) -> (set-foo a b c new-value)
         (and (= symbol/set head)
              (is/pair (k/car  tail))
              (is <symbol> (k/caar tail))
              (let ((buf (new_buffer)))
                (buffer_append_all buf "set-")
                (buffer_append_all buf (get/symbol (get/head (get/head tail))))
                (set head (intern (buffer_contents buf)))
                (set tail (k/concat-list (get/tail (get/head tail)) (get/tail tail)))))
         (set exp (new-<pair> head tail))
         (gc/pop-root (address-of tail))
         (gc/pop-root (address-of head)))))
    ((is <symbol> exp)
     (let ((val (k/env/lookup-variable env exp)))
          (and (is <variable> val) (set val (get <variable> value val)))
          (and (is <form> val)
               (let ((fn (get <form> symbol val)))
                 (and fn
                      (let ((args (new-<pair> exp ())))
                        (gc/protect (args)
                          (set args (new-<pair> env args))
                          (set args (k/apply fn args ()))
                          (set exp (k/expand args env)))))))))
    (else ; consult the *expanders* array to see if there's any custom expander for this type
     (let ((fn (k/array-at (get/variable-value var/*expanders*) (get/type exp))))
        (and fn
             (let ((args (new-<pair> exp ())))
               (gc/protect (args)
                 (set exp (k/apply fn args ()))))))))
  exp)

(set exlist (lambda (list env)
  (if (is/pair list)
      (let ((head (k/expand (get/head list) env)))
        (gc/protect (head)
          (let ((tail (exlist (get/tail list) env)))
            (gc/protect (tail)
              (new-<pair> head tail)))))
    (k/expand list env))))

(define enlist) ; forward

(define-function k/encode (exp env)
  (debug (libc/printf "k/encode, exp ") (k/dump exp) (libc/printf ", env ") (k/dump env) (libc/printf "\n"))
  (if (is/pair exp)
      (let ((head (k/encode (get/head exp) env))
	    (tail (get/tail exp)))
	(gc/protect (head tail)
	  (cond
	    ((= head fixed-subr/let)	(let ((bindings (k/cadr exp)))
					  (gc/protect (env)
					    (set env (new-<env> env 0 (get/long (get <env> offset env))))
					    (while (is/pair bindings)
					      (let ((var-name (get/head bindings)))
						(and (is/pair var-name) (set var-name (get/head var-name)))
						(k/env/define env var-name ())
						(set bindings (get/tail bindings))))
					    (set tail (enlist tail env))
					    (set tail (new-<pair> env tail)))))
	    ((= head fixed-subr/lambda)	(let ((args (k/cadr exp)))
					  (gc/protect (env)
					    (set env (new-<env> env 1 0))
					    (while (is/pair args)
					      (k/env/define env (get/head args) ())
					      (set args (get/tail args)))
					    (and args (k/env/define env args ()))
					    (set tail (enlist tail env))
					    (set tail (new-<pair> env tail)))))
            ;; TODO this defines the variable in the encode phase, even if the code is not executed in the end.
            ;; i doubt it's the intended behavior... investigate!
	    ((= head fixed-subr/define)	(let ((var (k/env/ensure-variable (get/globals) (k/car tail))))
					  (set tail (enlist (k/cdr tail) env))
					  (set tail (new-<pair> var tail))))
            ;; TODO this fails while expanding a branch that is _not_ taken at the end at runtime
	    ((= head fixed-subr/set)	(let ((var (k/env/lookup-variable env (k/car tail))))
					  (or var (fatal1 "set: undefined variable: %s" (get/symbol (k/car tail))))
                                          (and (or (not (k/car tail)) (k/cddr tail)) (k/error "encode: malformed SET expression " exp))
					  (set tail (enlist (k/cdr tail) env))
					  (set tail (new-<pair> var tail))))
	    ((!= head fixed-subr/quote)	(set tail (enlist tail env))))
	  (set exp (new-<pair> head tail))))
    (if (is <symbol> exp)
	(let ((val (k/env/lookup-variable env exp)))
	  (or val (fatal1 "undefined variable: %s" (get/symbol exp)))
	  (set exp val)
	  (if (global-variable? exp)
	      (let ((v (get <variable> value exp)))
		(and (or (is <form> v) (is <fixed> v))
		     (set exp v)))
	    (let ((venv (get <variable> env exp)))
	      (or (= (get/long (get <env> level venv)) (get/long (get <env> level env)))
		  (put <env> stable venv symbol/t)))))
      (let ((fn (k/array-at (get/variable-value var/*encoders*) (get/type exp))))
	(and fn
	     (let ((args (new-<pair> env ())))
	       (gc/protect (args)
		 (set args (new-<pair> exp args))
		 (debug (libc/printf "APPLY ENCODER\n... ") (k/print fn) (libc/printf " ") (k/print args) (libc/printf " ") (k/println env))
		 (set exp (k/apply fn args ()))))))))
  exp)

(set enlist (lambda (list env)
  (if (is/pair list)
      (let ((head (k/encode (get/head list) env)))
        (gc/protect (head)
          (let ((tail (enlist (get/tail list) env)))
            (gc/protect (tail)
              (new-<pair> head tail)))))
    (k/encode list env)))
)

(define-function evlist (obj ctx)
  (if (is/pair obj)
      (let ((head (k/eval (get/head obj) ctx)))
        (gc/protect (head)
          (let ((tail (evlist (get/tail obj) ctx)))
            (gc/protect (tail)
              (new-<pair> head tail)))))
    obj))

(set k/eval (lambda (exp ctx)
  (and (< 2 *arg/verbose*) (let () (libc/printf "  E  ")  (k/dump exp)  (libc/printf " ") (k/dumpln ctx)  (libc/flush-streams)))
  (let ((type (get/type exp)))
    (cond
      ((= type <undefined>)	exp)
      ((= type <long>)		exp)
      ((= type <string>)	exp)
      ((= type <variable>)	(if (global-variable? exp)
				    (get <variable> value exp)
				  (let ((delta (- (get/long (get <env> level (get <context>  env ctx)))
					      (get/long (get <env> level (get <variable> env exp))))))
				    (while (< 0 delta)
				      (set ctx (get <context> home ctx))
				      (set delta (- delta 1)))
				    (k/array-at (get <context> bindings ctx) (get/long (get <variable> index exp))))))
      ((= type <pair>)		(let ((raw-head (get/head exp)))
                                  (debug (libc/printf "k/eval of pair, raw-head (of type %d) is " (get/type raw-head)) (k/dumpln raw-head))
				  (gc/let* ((head (k/eval raw-head ctx)))
                                    (debug (libc/printf "k/eval of pair, head eval'ed to ") (k/dumpln head))
				    (k/set-array-at *backtrace-stack* *backtrace-index* exp)
				    (set *backtrace-index* (+ *backtrace-index* 1))
				    (set head (if (is <fixed> head)
						  (k/apply (get <fixed> function head) (get/tail exp) ctx)
						(let ((args (evlist (get/tail exp) ctx)))
						  (gc/protect (args)
						    (k/apply head args ctx)))))
				    (set *backtrace-index* (- *backtrace-index* 1))
                                    (debug (libc/printf "k/eval of pair, returning with head ") (k/dumpln head))
				    head)))
      ((= type <symbol>)	(k/error "symbol in eval?")) ;; TODO xxx
      (else			(let ((ev (k/array-at (get/variable-value var/*evaluators*) (get/type exp))))
				  (and ev
				       (let ((args (new-<pair> exp ())))
					 (gc/protect (args)
					   (k/set-array-at *backtrace-stack* *backtrace-index* exp)
					   (set *backtrace-index* (+ *backtrace-index* 1))
					   (set exp (k/apply ev args ctx))
					   (set *backtrace-index* (- *backtrace-index* 1)))))
				  exp)))))
     )

(define-function k/expand-encode-eval (form env)
  (gc/let* ((x form)
            (ctx (new-base-<context> () () env)))
								(when (< 0 *arg/verbose*) (libc/printf ";;; ")		(k/dumpln x))
    (set x (k/expand x env))					(when (< 2 *arg/verbose*) (libc/printf "expd--> ")	(k/dumpln x))
    (set x (k/encode x env))					(when (< 2 *arg/verbose*) (libc/printf "encd--> ")	(k/dumpln x))
    (set x (k/eval   x ctx))
								(when (< 0 *arg/verbose*) (libc/printf ";;; => ")	(k/dumpln x))
    x))

(define-function k/repl-stream (stream)
  (put/variable-value var/*input* (new-<long> stream))
  (gc/let* ((res ()))
    (unless (= libc/stdin stream)
      (libc/fscanf stream "#!%*[^\012\015]")) ; drop the possible #!./eval first line of the file
    (while (let ()
             (when (= libc/stdin stream)
               (libc/fprintf libc/stdout ".")
               (libc/flush-streams))
             (!= k/+done+ (set res (k/read stream))))
      (gc/let* ((env (new-<env> (get/globals) 1 0)))
        (set res (k/expand-encode-eval res env))
        (when (= libc/stdin stream)
          (k/dumpln res))))
    (and (= libc/stdin stream)
         (libc/printf "\nmorituri te salutant\n"))
    res))

;;;
;;; the subr's
;;;
(define-form define-subr (name-and-props . body)
  (unless (pair? name-and-props)
    (set name-and-props (list name-and-props)))
  (let ((name (car name-and-props))
        (arity (cadr name-and-props))
        (fixed? (caddr name-and-props)))
    (assert (symbol? name))
    (push *subr-registry* (list name arity fixed?))
    `(define-function ,(concat-symbol 'subr/ name) (-args- -ctx-)
       ,@(when arity
           `((safety 2 (%check-arity (new-<string>-from-cstring ,(symbol->string name)) ,arity -args-))))
       ,@body)))

(define-function %check-arity (op arity args)
  (let ((count arity)
        (lst args))
    (while (and (< 0 count)
                (is/pair lst))
      (set lst (get/tail lst))
      (set count (- count 1)))
    (or (and (= 0 count) (not lst))
        (k/error "Operator '" op "' called with the wrong number of arguments: " args))))

(define-subr (define () fixed)
  (let ((var (k/car -args-)))
    (unless (is <variable> var)
      ;; FIXME? use k/error? why the dumpln? test it...
      (libc/printf "\nerror: non-variable in define: ")
      (k/dumpln var)
      (fatal "aborting"))
    (let ((val (k/eval (k/cadr -args-) -ctx-)))
      (put <variable> value var val))))

(define-subr (defined? 1)
  (let ((name (k/car -args-))
        (env (or (k/cadr -args-) (get/globals))))
    (k/env/lookup-variable env name)))

(define-subr (lambda () fixed)
  (new-<expr> -args- -ctx-))

(define-subr (let () fixed)
  (let* ((tmp      ())
         (bindings (k/cadr -args-))
         (locals   (get <context> bindings -ctx-))
         (body     (k/cddr -args-)))
    (gc/protect (tmp)
      (while (is/pair bindings)
        (let ((binding (get/head bindings)))
          (when (is/pair binding)
            (let ((var  (get/head binding))
                  (prog (get/tail binding)))
              (set tmp ())
              (while (is/pair prog)
                (set tmp (k/eval (get/head prog) -ctx-))
                (set prog (get/tail prog)))
              (k/set-array-at locals (get/long (get <variable> index var)) tmp))))
        (set bindings (get/tail bindings)))
      (set tmp ())
      (while (is/pair body)
        (set tmp (k/eval (get/head body) -ctx-))
        (set body (get/tail body))))
    tmp))

(define-subr (set 2 fixed)
  ;;(printf "SET ") (k/print args) (libc/printf " IN ") (k/println -ctx-)
  (let ((var (k/car -args-)))
    (or (is <variable> var)
        (let ()
          ;; FIXME? use k/error? why the dumpln? test it... was: (k/error "undefined variable: (set "-args-")")
          (libc/printf "\ncannot set undefined variable: ")
          (k/dumpln var)
          (fatal "aborting")))
    (let ((val (k/eval (k/cadr -args-) -ctx-)))
      (if (global-variable? var)
          (put <variable> value var val)
        (let ((delta (- (get/long (get <env> level (get <context>  env -ctx-)))
                        (get/long (get <env> level (get <variable> env var))))))
          (while (< 0 delta)
            (set -ctx- (get <context> home -ctx-))
            (set delta (- delta 1)))
          (k/set-array-at (get <context> bindings -ctx-) (get/long (get <variable> index var)) val))))))

(define-subr (while () fixed)
  (let ((tst  (k/car -args-))
        (prog -args-))
    (while (k/eval tst -ctx-)
      (let ((body prog))
        (while (is/pair (set body (k/cdr body)))
          (k/eval (get/head body) -ctx-))))))

(define-subr (if () fixed)
  (if (k/eval (k/car  -args-) -ctx-)
      (k/eval (k/cadr -args-) -ctx-)
    (let ((ans ()))
      (set -args- (k/cdr -args-))
      (while (is/pair (set -args- (k/cdr -args-)))
        (set ans (k/eval (get/head -args-) -ctx-)))
      ans)))

(define-subr (or () fixed)
  (let ((ans ()))
    (while (is/pair -args-)
      (and (set ans (k/eval (get/head -args-) -ctx-))
           (return ans))
      (set -args- (get/tail -args-)))))

(define-subr (and () fixed)
  (let ((ans symbol/t))
    (while (is/pair -args-)
      (or (set ans (k/eval (get/head -args-) -ctx-))
          (return ()))
      (set -args- (get/tail -args-)))
    ans))

(define-subr (quote 1 fixed)
  (k/car -args-))

(define-subr (not 1)
  (if (k/car -args-) () symbol/t))

(define-subr (fixed 1)
  (new-<fixed> (k/car -args-)))

(define-subr (variable 4)
  (new-<variable> (k/car -args-) (k/cadr -args-) (k/caddr -args-) (k/cadddr -args-)))

(define-subr (environment 1)
  (let ((parent (k/car -args-)))
    (k/assert (is <env> parent))
    (new-<env> parent 0 (get/long (get <env> offset parent)))))

(define-subr (environment-define 3)
  (let ((env   (k/car -args-))
        (name  (k/cadr -args-))
        (value (k/caddr -args-)))
    (k/assert (is <env> env))
    (k/assert (is <symbol> name))
    (let* ((bindings (get <env> bindings env))
           (offset (get/long (get <env> offset env)))
           (var (new-<variable> name value env offset)))
      (gc/protect (var)
        (put <env> offset env (new-<long> (+ offset 1)))
        (k/array-append bindings var)
        var))))

(define-subr -
  (safety 1 (or (and (k/car -args-) (not (k/cddr -args-))) (k/error "operator '-' expected 1 or 2 arguments, got: " -args-)))
  (let ((lhs (get/head -args-))
        (rhs (get/tail -args-)))
    (if (is/pair rhs)
        (let ()
          (set rhs (get/head rhs))
          (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (- "lhs" "rhs")")))
          (new-<long> (- (get/long lhs) (get/long rhs))))
      (safety 1 (or (is/long lhs) (k/error "non-numeric argument: (- "lhs")")))
      (new-<long> (- (get/long lhs))))))

(define-form define-binary (op)
  `(define-subr (,op 2)
     (let ((lhs (get/head -args-))
           (rhs (get/head (get/tail -args-))))
       (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (",(symbol->string op)" "lhs" "rhs")")))
       (new-<long> (,op (get/long lhs) (get/long rhs))))))

(define-binary &)
(define-binary |)
(define-binary ^)
(define-binary +)
(define-binary *)
(define-binary /)
(define-binary <<)
(define-binary >>)

(define-form define-relation (op)
  `(define-subr (,op 2)
     (let ((lhs (get/head -args-))
           (rhs (get/head (get/tail -args-))))
       (safety 1 (or (and (is/long lhs) (is/long rhs)) (k/error "non-numeric argument: (",(symbol->string op)" "lhs" "rhs")")))
       (and (,op (get/long lhs) (get/long rhs))
            symbol/t))))

(define-relation <)
(define-relation <=)
(define-relation >=)
(define-relation >)

(define-subr (= 2)
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (get/type lhs)))
    (cond
      ((= type <long>)          (and (is/long rhs) (= (get/long lhs) (get/long rhs)) symbol/t))
      ((= type <string>)        (and (is <string> rhs) (not (libc/strcmp (get/string lhs) (get/string rhs))) symbol/t))
      (else                     (and (= lhs rhs) symbol/t)))))

(define-subr (!= 2)
  (let* ((lhs  (get/head -args-))
         (rhs  (get/head (get/tail -args-)))
         (type (get/type lhs)))
    (cond
      ((= type <long>)          (and (is/long rhs) (!= (get/long lhs) (get/long rhs)) symbol/t))
      ((= type <string>)        (and (is <string> rhs) (libc/strcmp (get/string lhs) (get/string rhs))) symbol/t)
      (else                     (and (!= lhs rhs) symbol/t)))))

(define-subr (abort 0)
  (print-backtrace)
  (libc/flush-streams)
  (libc/abort))

(define-subr (exit 1)
  (let ((arg (k/car -args-)))
    (or (is/long arg)
        (k/error "argument to subr_exit is not a <long>: " arg))
    (libc/flush-streams)
    (libc/exit (get/long arg))))

(define-subr (libc/fopen 1)
  (let ((path (k/car -args-)))
    (let ((stream (libc/fopen (get/string path) "rb")))
      (and stream (new-<target-vm-pointer> stream)))))

(define-subr (libc/fclose 1)
  (let ((stream (k/car -args-)))
    (libc/fclose (get/tptr stream))
    ()))

(define-subr libc/fgetc
  (let ((stream (k/car -args-)))
    (or stream (set stream (get/variable-value var/*input*)))
    (let ((c (libc/fgetc (get/tptr stream))))
      (and (>= c 0)
           (new-<long> c)))))

(define-subr libc/fputc
  (let ((stream (k/car -args-))
        (obj (k/cadr -args-)))
    (or stream (set stream (get/variable-value var/*input*)))
    (new-<long> (libc/fputc (get/tptr stream) (get/long obj)))))

(define-subr (libc/format 2)
  (let ((ofmt (k/car -args-))
        (oarg (k/cadr -args-)))
    (or (is <string> ofmt) (fatal "subr/libc/format: non-string format"))
    (let ((fmt (get/string ofmt))
          (typ (get/type oarg))
          (arg ()))
      (cond
        ((= typ <undefined>))
        ((= typ <long>)		(set arg (get/long oarg)))
        ((= typ <string>)	(set arg (get/string oarg)))
        ((= typ <symbol>)	(set arg (get/symbol oarg)))
        (else			(set arg oarg)))
      (let ((size 100)
            (p)
            (np))
        (or (set p (libc/malloc size))
            (return "out of memory"))
        (while 1
          (let ((n (libc/snprintf p size fmt arg)))
            (and (<= 0 n) (< n size)
                 (let ((ans (new-<string>-from-cstring p)))
                   (libc/free p)
                   (return ans)))
            (set size (* size 2)))
          (or (set np (libc/realloc p size))
              (let ()
                (libc/free p)
                (return "out of memory")))
          (set p np))))))

(define-subr repl-stream
  (let ((stream (k/car -args-)))
    (or stream (set stream (get/variable-value var/*input*)))
    (k/repl-stream (get/tptr stream))))

(define-subr dump
  (while (is/pair -args-)
    (k/dump (get/head -args-))
    (set -args- (get/tail -args-))))

(define-subr print
  (while (is/pair -args-)
    (k/print (get/head -args-))
    (set -args- (get/tail -args-))))

(define-subr warn
  (while (is/pair -args-)
    (let* ((arg  (get/head -args-))
           (type (get/type arg)))
      (cond
        ((= type <string>) (libc/fprintf libc/stderr "%s" (get/string arg)))
        ((= type <symbol>) (libc/fprintf libc/stderr "%s" (get/symbol arg)))
        ((= type <long>)   (libc/fprintf libc/stderr "%d" (get/long   arg)))
        (else
         ;; TODO
         (libc/fprintf libc/stderr "<unable to print {%p} of type %d>" arg type))))
    (set -args- (get/tail -args-))))

(define-subr (apply 2)
  (k/apply (k/car -args-) (k/cadr -args-) -ctx-))

(define-subr eval
  (gc/let* ((e (or (k/cadr -args-) (new-<env> (get/globals) 1 0))))
    (k/expand-encode-eval (k/car -args-) e)))

(define-subr encode
  (k/encode (k/car -args-)
            (or (k/cadr -args-)
                (get <context> env -ctx-))))

(define-subr expand
  (k/expand (k/car -args-)
            (or (k/cadr -args-)
                (get <context> env -ctx-))))

(define-subr cons       (new-<pair> (k/car -args-) (k/cadr -args-)))
(define-subr (string 1) (new-<string>-of-length (and (is/long (k/car -args-)) (get/long (get/head -args-)))))
(define-subr array      (new-<array> (and (is/long (k/car -args-)) (get/long (get/head -args-)))))
(define-subr form       (new-<form> (k/car -args-) (k/cadr -args-)))

(define-subr (allocate 2)
  (let ((type (get/head -args-))
        (size (get/head (get/tail -args-))))
    (safety 1 (k/assert (is/long type) "allocate: invalid type "type))
    (safety 1 (k/assert (is/long size) "allocate: invalid size "size))
    (new-object (get/long type) (get/long size))))

(define-subr (type-of 1) (and -args- (new-<long> (get/type (k/car -args-)))))
(define-subr (string? 1) (and (is <string> (k/car -args-)) symbol/t))
(define-subr (symbol? 1) (and (is <symbol> (k/car -args-)) symbol/t))
(define-subr (pair? 1)   (and (is <pair>   (k/car -args-)) symbol/t))
(define-subr (array? 1)  (and (is <array>  (k/car -args-)) symbol/t)) ; TODO move to boot.l?
(define-subr (car 1)     (k/car (k/car -args-)))
(define-subr (cdr 1)     (k/cdr (k/car -args-)))

(define-subr (set-car 2)
  (let ((obj (k/car -args-)))
    (and (is/pair obj)
         (put <pair> head obj (k/cadr -args-)))))

(define-subr (set-cdr 2)
  (let ((obj (k/car -args-)))
    (and (is/pair obj)
         (put <pair> tail obj (k/cadr -args-)))))

(define-subr (oop-at 2)
  (let ((obj (get/head -args-))
        (idx (get/head (get/tail -args-))))
    (safety 1 (k/assert (and obj (is/long idx) (not (is/long obj)))))
    (oop-at obj (get/long idx))))

(define-subr (set-oop-at 3)
  (let ((obj (get/head -args-))
        (idx (get/head (get/tail -args-)))
        (val (get/head (get/tail (get/tail -args-)))))
    (safety 1 (k/assert (and obj (is/long idx) (not (is/long obj)))))
    (set-oop-at obj (get/long idx) val)))

(define-subr (array-length 1)
  (new-<long> (k/array-length (k/car -args-))))

(define-subr (array-at 2)
  (let ((arr (get/head -args-))
        (idx (get/head (get/tail -args-))))
    (safety 1 (k/assert (and (is <array> arr) (is/long idx))))
    (k/array-at arr (get/long idx))))

(define-subr (set-array-at 3)
  (let ((arr (get/head -args-))
        (idx (get/head (get/tail -args-)))
        (val (get/head (get/tail (get/tail -args-)))))
    (safety 1 (k/assert (and (is <array> arr) (is/long idx))))
    (k/set-array-at arr (get/long idx) val)))

(define-subr (array-insert 3)
  (let ((arr (get/head -args-))
        (idx (get/head (get/tail -args-)))
        (val (get/head (get/tail (get/tail -args-)))))
    (safety 1 (k/assert (and (is <array> arr) (is/long idx))))
    (k/array-insert arr (get/long idx) val)))

(define-subr (string-length 1)
  (let ((arg (k/car -args-)))
    (safety 1 (k/assert (is <string> arg)))
    (get <string> size arg)))

(define-subr (string-at 2)
  (let ((arr (get/head -args-))
        (arg (get/head (get/tail -args-))))
    (safety 1 (k/assert (and (is <string> arr) (is/long arg))))
    (let ((idx (get/long arg)))
      (and (<= 0 idx)
           (< idx (k/string-length arr))
           (new-<long> (string-at (get/string arr) idx))))))

(define-subr (set-string-at 3)
  (let ((arr (get/head -args-))
        (arg (get/head (get/tail -args-)))
        (val (get/head (get/tail (get/tail -args-)))))
    (safety 1 (k/assert (and (is <string> arr) (is/long val))))
    (let ((idx (get/long arg)))
      (and (<= 0 idx)
           (< idx (k/string-length arr))
           ;; TODO don't just silently ignore wrong indexes?
           (let ()
             (set-string-at (get/string arr) idx (get/long val))
             val)))))

(define-subr (string->symbol 1)
  (let ((arg (k/car -args-)))
    (if (is <symbol> arg)
        arg
      (and (is <string> arg)
           (intern (get/string arg))))))

(define-subr (symbol->string 1)
  (let ((arg (k/car -args-)))
    (if (is <string> arg)
        arg
      (and (is <symbol> arg)
           (new-<string>-from-cstring (get <symbol> _bits arg))))))

(define-subr (long->string 1)
  (let ((arg (k/car -args-)))
    (if (is <string> arg)
        arg
      (and (is/long arg)
           (let ((buf (libc/malloc 32)))
             (libc/sprintf buf "%ld" (get/long arg))
             (let ((result (new-<string>-from-cstring buf)))
               (libc/free buf)
               result))))))

;; TODO is this the actual primitive that we want to publish? maybe a just read-form?
(define-subr read
  (if (= () -args-)
      (let ((obj (k/read libc/stdin)))
        (and (= k/+done+ obj) (set obj ()))
        obj)
    (let ((arg (k/car -args-)))
      (or (is <string> arg) (fatal1 "read: non-String argument: " arg))
      (let* ((path   (get/string arg))
             (stream (libc/fopen path "r")))
        ;; TODO error handling
        (if stream
            (let* ((head (new-<pair> () ()))
                   (tail head)
                   (obj  ()))
              (gc/protect (head obj)
                (while (!= k/+done+ (set obj (k/read stream)))
                  (set tail (put/tail tail (new-<pair> obj ())))))
              (libc/fclose stream)
              (get/tail head))
          ())))))

(define-subr (current-module 0)
  *module*)

(define capture-well-known-vm-values) ; forward
(define populate-module-with-primitives) ; forward

(define-function k/set-current-module (module)
  (debug (libc/printf "k/set-current-module {%p}\n" module))
  (set *module* module)
  (capture-well-known-vm-values))

(define-subr (set-current-module 1)
  (let ((module (k/car -args-)))
    (safety 1 (k/assert (is <module> module) "set-current-module: called with not a <module>: "module))
    (k/set-current-module module))
  ())

(define-subr (create-module 0)
  (gc/let* ((module (new-<module>)))
    (populate-module-with-primitives module)
    module))

(define-subr (eval-in-module 2)
  (let ((new-module (k/car -args-))
        (form (k/cadr -args-))
        (previous-module *module*))
    (safety 1 (k/assert (is <module> new-module) "eval-in-module: called with not a <module>: "new-module))
    (debug (libc/printf "eval-in-module: form ") (k/dumpln form))
    (k/set-current-module new-module)
    (gc/let* ((result (k/expand-encode-eval form (get/globals* new-module))))
      (k/set-current-module previous-module)
      (debug (libc/printf "eval-in-module is done\n"))
      result)))

;;; ----------------------------------------------------------------

(define-function %instantiate-subr (name imp fixed? module)
  (gc/let* ((tmp (new-<subr> imp name)))
    (when fixed?
      (set tmp (new-<fixed> tmp)))
    (k/env/define (get/globals* module) (intern* name module) tmp)))

(define-form instantiate-subrs ()
  (let ((result ()))
    (list-do entry *subr-registry*
      (let* ((name (car entry))
             (impl-name (concat-symbol 'subr/ name))
             (fixed? (caddr entry)))
        (push result `(%instantiate-subr ,(symbol->string name) ,impl-name ,(target-boolean fixed?) module))))
    `(let () ,@result)))

(set populate-module-with-primitives (lambda (module)
  (debug (libc/printf "populate-module-with-primitives on %p\n" module))
  (safety 1 (k/assert (is <module> module) "populate-module-with-primitives: called with not a <module>: "module))
  ;; the predefined primitives of the language
  (let ((env (get/globals* module))
        (tmp))
    (gc/protect (tmp)
				(k/env/define env (intern* "*input*"			module) ())
				(k/env/define env (intern* "*command-line-arguments*"	module) ())
      (set tmp (new-<long> 0))	(k/env/define env (intern* "*verbosity*"		module) tmp)
      (set tmp (new-<long> 0))	(k/env/define env (intern* "*optimised*"		module) tmp)

      (k/env/define env (intern* "+done+" module) k/+done+)

      (set tmp (new-<array> 0))	(k/env/define env (intern* "*expanders*"		module) tmp)
      (set tmp (new-<array> 0))	(k/env/define env (intern* "*encoders*"			module) tmp)
      (set tmp (new-<array> 0))	(k/env/define env (intern* "*evaluators*"		module) tmp)
      (set tmp (new-<array> 0))	(k/env/define env (intern* "*applicators*"		module) tmp))

    (instantiate-subrs))))

(set capture-well-known-vm-values (lambda ()
  (debug (libc/printf "capture-well-known-vm-values from *module*, which is %p\n" *module*))
  ;; let's cache some values from *module* to speed up their access in tight loops
  (set symbol/t                      (intern "t"))
  (set symbol/dot                    (intern "."))
  (set symbol/define                 (intern "define"))
  (set symbol/set                    (intern "set"))
  (set symbol/quote                  (intern "quote"))
  (set symbol/quasiquote             (intern "quasiquote"))
  (set symbol/unquote                (intern "unquote"))
  (set symbol/unquote_splicing       (intern "unquote-splicing"))

  (let ((global-env (get/globals)))
    (set var/*expanders*	(k/env/lookup-variable-or-die global-env (intern "*expanders*")))
    (set var/*encoders*		(k/env/lookup-variable-or-die global-env (intern "*encoders*")))
    (set var/*evaluators*	(k/env/lookup-variable-or-die global-env (intern "*evaluators*")))
    (set var/*applicators*	(k/env/lookup-variable-or-die global-env (intern "*applicators*")))
    (set var/*input*		(k/env/lookup-variable-or-die global-env (intern "*input*")))

    (set fixed-subr/quote  (k/env/variable-value global-env (intern "quote")))
    (set fixed-subr/lambda (k/env/variable-value global-env (intern "lambda")))
    (set fixed-subr/let    (k/env/variable-value global-env (intern "let")))
    (set fixed-subr/define (k/env/variable-value global-env (intern "define")))
    (set fixed-subr/set    (k/env/variable-value global-env (intern "set")))

    (k/assert (and (is <fixed> fixed-subr/quote) (is <fixed> fixed-subr/lambda) (is <fixed> fixed-subr/let) (is <fixed> fixed-subr/define) (is <fixed> fixed-subr/set)) "capture-well-known-vm-values: assert 2"))

  (debug (libc/printf "capture-well-known-vm-values is done\n"))))

(define-function main (argc argv)
  ;; we need to dereference them once
  (set libc/stdin  (oop-at libc/stdin 0))
  (set libc/stdout (oop-at libc/stdout 0))
  (set libc/stderr (oop-at libc/stderr 0))

  (gc/initialise)

  (safety 4 (set gc/frequency 1))

  (debug (libc/printf "gc initialized\n"))

  (k/assert (= <long> (get/type (new-<long> 42))) "get/type for <long> is broken")
  (k/assert (= 42     (get/long (new-<long> 42))) "get/long is broken")

  (set k/+done+ (new-<symbol> "+done+")) ; an uninterned symbol, i.e. a unique identity that cannot be recreated any other way
  (gc/push-root (address-of k/+done+))

  (gc/push-root (address-of *module*))			; the gc root for all (module-)global definitions
  (gc/push-root (address-of *backtrace-stack*))
  (gc/push-root (address-of fixed-subr/quote))		; precautionary, in case someone redefines them and they get removed from the env.
  (gc/push-root (address-of fixed-subr/lambda))
  (gc/push-root (address-of fixed-subr/let))
  (gc/push-root (address-of fixed-subr/define))

  (debug (libc/printf "initializing *module*\n"))

  (set *module* (new-<module>))

  (debug (libc/printf "*module* initialized\n"))

  (set *backtrace-stack* (new-<array> 32))

  (debug (libc/printf "populating *module*\n"))

  (populate-module-with-primitives *module*)
  (capture-well-known-vm-values)

  (debug (libc/printf "start processing argv\n"))

  ;; *command-line-arguments*
  (let ((cla-var (k/env/lookup-variable (get/globals) (intern "*command-line-arguments*"))))
    ;; initialize *cla*
    (gc/let* ((tmp ()))
      (while (< 0 (set argc (- argc 1)))
        (set tmp (new-<pair> () tmp))
        (put/head tmp (new-<string>-from-cstring (oop-at argv argc))))
      (put <variable> value cla-var tmp))

    ;; process *cla*
    (let (cla tmp)
      (while (is/pair (set cla (get <variable> value cla-var)))
        (let ((arg-string	(get/head cla))
              (arg		(get/string arg-string)))
          (gc/protect (arg-string tmp)
            (put <variable> value cla-var (set cla (get/tail cla))) ; (pop *command-line-arguments*)
            (cond
              ((not (libc/strcmp arg "-v"))
               (set *arg/verbose* (+ 1 *arg/verbose*))
               (set tmp (new-<long> *arg/verbose*))
               (put/variable-value "*verbosity*" tmp))
              ((not (libc/strcmp arg "-O"))
               (set *arg/optimised* (+ 1 *arg/optimised*))
               (set tmp (new-<long> *arg/optimised*))
               (put/variable-value "*optimised*" tmp))
              ((not (libc/strcmp arg "-"))
               (k/repl-stream libc/stdin))
              ((not (libc/strcmp arg "-c"))
               (unless (is/pair cla)
                 (fatal "-c requires an argument"))
               (set arg-string (get/head cla))
               (set arg (get/string arg-string))
               (put <variable> value cla-var (set cla (get/tail cla))) ; (pop *command-line-arguments*)
               (let* ((sym (intern arg))
                      (form (new-<pair> sym ())))
                 (gc/protect (form)
                   (k/eval form (get/globals)))))
              (else
               (let ((stream (libc/fopen arg "r")))
                 (or stream (fatal1 "no such file: %s" arg))
                 (k/repl-stream stream)
                 (libc/fclose stream)))))))))

  (libc/flush-streams)
  (and (< 0 *arg/verbose*)
       (let ()
         (gc/collect)
         (libc/printf "GC: %d objects in %d bytes, %d free\n" gc/objects-live gc/bytes-used gc/bytes-free)))

  (libc/fprintf libc/stderr "%d objects in %d bytes, %d free\n" gc/objects-live gc/bytes-used gc/bytes-free)
  (libc/flush-streams)
  (return 0))

(compile-end)
