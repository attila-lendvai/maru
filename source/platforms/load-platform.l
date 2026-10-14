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

;; The x86 backend emits 32- or 64-bit code; which one is a property of
;; the target arch, not the backend. The normalized arch symbol already
;; spells the suffix (x86-32 / x86-64), matching the emitter file names.
(define-function emitter-name (backend-name)
  (if (= backend-name "x86")
      (symbol->string (target-value target/arch))
    backend-name))

(require (concat-strings "source/compiler/emit-" (emitter-name *compiler-backend*) ".l"))

(switch-to-target-env)

(load (host-value (concat-strings "source/platforms/"target/platform"/"target/platform".l")))
