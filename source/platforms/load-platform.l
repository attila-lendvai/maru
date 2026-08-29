;;; -*- mode: lisp; coding: us-ascii -*-

;; this must happen early, before loading the compiler
;; TODO add [platform]-early.l files?
(eval-in-slave `(set (feature cffi)
                     ,(or (= target/platform "libc")
                          (= target/platform "posix"))))

(load "source/compiler/target.l")

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

(require (concat-strings "source/compiler/emit-" *compiler-backend* ".l"))

(switch-to-target-env)

(load (host-value (concat-strings "source/platforms/"target/platform"/"target/platform".l")))
