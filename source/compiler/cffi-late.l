;;; -*- mode: lisp; coding: us-ascii -*-

;;; FFI: one zeroed data cell per external, filled by ld.so through an
;;; R_*_GLOB_DAT relocation. Backend-agnostic; the trampolines that
;;; jump through these cells are emitted per backend.
(define-function emit-external-got-cell (entry -c-)
  ;; the 'load-time strategy materializes the external's address in a
  ;; data cell; it's filled by ld.so through an R_*_GLOB_DAT
  ;; relocation in the standalone image, and by the static linker
  ;; through an R_*_64 one (pointing at the UND symbol) in the c-obj.
  (or (<external-symbol>-got-label entry)
      (let ((label (with-new-label 'data
                     (if (= "c-obj" elf-emission-type)
                         (.i64 (reloc-symbol (<external-symbol>-name entry)))
                       (emit CELL 0)))))
        (set (<external-symbol>-got-label entry) label)
        label)))

;;; FFI: a C-function gets a code trampoline that jumps through its GOT
;;; cell. The GOT cell is emitted at the first reference, and the
;;; trampoline's bytes are emitted after the code pass (see
;;; emit-deferred-external-trampolines), so externals that are defined
;;; but never referenced (e.g. libc.c wrappers) never end up in
;;; .dynsym/.rela.dyn, where ld.so would fail to resolve them eagerly.
(define-function external-trampoline-label (c-function -c-)
  (let ((entry (register-external-symbol (<C-function>-name c-function))))
    (or (<external-symbol>-trampoline-label entry)
        (let ((label (label (string->symbol (concat-string (<C-function>-name c-function)
                                                           "-trampoline")))))
          (set (<external-symbol>-trampoline-label entry) label)
          (emit-external-got-cell entry -c-)
          label))))

(define-method compile-definition <C-variable>		(name -c-)
  (emit-external-got-cell (register-external-symbol (<C-variable>-name self)) -c-))

(define-method compile-definition <C-function>		(name -c-))

;; The trampoline's label is pre-created by external-trampoline-label
;; as a forward label, and its bytes are emitted here after the code
;; pass. The jump through the GOT cell is backend-specific; only x86
;; implements FFI calls so far.
(define-function emit-deferred-external-trampolines (-c-)
  (list-do entry *external-symbols*
    (when (<external-symbol>-trampoline-label entry)
      (with-current-segment 'code
        (label! (<external-symbol>-trampoline-label entry))
        (if-at-expand (= "x86" *compiler-backend*)
            (JMPQripm (<external-symbol>-got-label entry))
          (if-at-expand (= "arm" *compiler-backend*)
              (begin
                (ADR X16 (<external-symbol>-got-label entry))
                (LDR X16 X16 0)
                (BR X16))
            (error "emit-deferred-external-trampolines: FFI calls are not implemented for this backend")))))))

;; The process entry point, synthesized when the platform defines no
;; maru-level _start (e.g. libc, where the entry only needs to call
;; main and exit). Emitted after the code pass, so main's label is
;; already resolved.
;;
;; ld.so enters with rsp pointing at argc and rsp%16=0. The ABI
;; guarantees rsp%16=8 at function entry only because the caller's
;; call instruction pushes the return address; a process entry lacks
;; that push. Raw code without a prologue of its own therefore calls
;; at rsp%16=0, as the ABI requires, and the whole call chain below it
;; is properly 16-byte aligned. A compiled maru _start cannot achieve
;; this: its push rbp skews every frame by 8, which misaligns all C
;; calls and breaks varargs libc functions (movaps).
;;
;; The body is x86-specific; emit-arm.l defines the aarch64 version.
(if-at-expand (= "x86" *compiler-backend*)
    (define-function emit-entry-point-wrapper (-c-)
      (let ((desig (closure-code-label-desig '_start)))
        (unless (%find-label desig)
          (assert (%find-label (closure-code-label-desig 'main))
                  "the platform provides no '_start' and no 'main' for the entry wrapper")
          (with-current-segment 'code
            (label! desig)
            (MOVQmr 0 RSP 0 1 RDI)          ; mov rdi,[rsp]   ; argc
            (LEAQmr 8 RSP 0 0 RSI)          ; lea rsi,[rsp+8] ; argv
            (emit CALL (closure-code-label 'main))
            (MOVQrr RAX RDI)
            (CALLQripm (emit-external-got-cell (register-external-symbol "exit") -c-)))
          (emit-symtab-entry/function "_start"
                                      (laddress desig)
                                      (- (current-laddress)
                                         (laddress desig))))))
  ())
