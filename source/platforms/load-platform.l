;;; -*- mode: lisp; coding: us-ascii -*-

;; this must happen early, before loading the compiler
;; TODO add [platform]-early.l files?
(eval-in-slave `(set (feature cffi)
                     ,(or (= target/platform "libc")
                          (= target/platform "posix"))))

(load "source/compiler/setup-target.l")

(switch-to-target-env)

(load "source/platforms/target.l")

(switch-to-host-env)

;; The ET_REL c-obj emission (for the C toolchain) is the default on
;; the C-based platforms. The CLI key arrives as a string into the
;; host env through --define and overrides the platform default. Kept
;; as a string: the dispatch sites compare with (string =).
;;
;; TODO don't define such things into the llvm backend...
(eval-in-slave `(define elf-emission-type
                  ,(or (and (defined? 'elf-emission-type)
                            elf-emission-type)
                       (if (or (= target/platform "libc")
                               (= target/platform "posix"))
                           "c-obj"
                         "standalone"))))

(eval-in-slave `(set (feature relocatable-elf)
                     ,(or (= target/platform "libc")
                          (= target/platform "posix")
                          (= elf-emission-type "c-obj"))))

;; Every emission shape anchors its heap on an image: the ELF writers
;; emit the arena's genesis, and the LLVM backend emits a zeroed global.
;; This must be a feature: the arena reloads gc.l in a child of the
;; slave env, and the branch has to agree there.
(eval-in-slave `(set (feature genesis) true))

;; Build and validate the host-side arena before the compiler starts.
;; Stage-0 still runs on the previous stage's binary, which predates
;; the boxed-word arithmetic. The arena is loaded in both later stages
;; so that its type registration is identical there.
(unless evolving?
  (load "source/compiler/arena.l"))

;; The normalized target/arch values each backend can emit for. A new
;; arch in setup-target.l must be paired with the backends implementing
;; it; otherwise a backend emits code for an ABI/ELF layout it does not
;; understand (e.g. `./build.sh bootstrap arm linux` on an x86_64 host
;; emits AArch64 code against x86-64 syscalls: a valid ELF that
;; segfaults instead of failing to build).
(define +backend/supported-targets+
  '(("x86"	(x86-32 x86-64))
    ("arm"	(aarch64))
    ("llvm"	(x86-32 x86-64 aarch64))))

;; The x86 backend emits 32- or 64-bit code; which one is a property of
;; the target arch, not the backend. The normalized arch symbol already
;; spells the suffix (x86-32 / x86-64), matching the emitter file names.
(define-function emitter-name (backend-name)
  (let* ((supported	(second (assq backend-name +backend/supported-targets+)))
         (arch		(target-value target/arch)))
    (unless (member? arch supported)
      (error "the "backend-name" backend does not support target/arch="target/arch
             ", supported: "supported))
    (if (= backend-name "x86")
        (symbol->string arch)
      backend-name)))

(require (concat-strings "source/compiler/emit-" (emitter-name *compiler-backend*) ".l"))

(switch-to-target-env)

(load (host-value (concat-strings "source/platforms/"target/platform"/"target/platform".l")))
