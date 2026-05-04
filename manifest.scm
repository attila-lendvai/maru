;; This is the complete list of Guix packages necessary for building Maru.
;;
;; Usage:
;;
;; guix shell
;; guix shell --pure -- make test
;; # if you want to protect the packages from guix gc:
;; guix package --manifest=manifest.scm --profile=.guix-profile
;; guix shell --profile=.guix-profile

;; TODO -m32 does not work as of 2025-06:
;; cc -O3 -m32 -o build/x86-libc/i386-linux-gnu/eval1  build/x86-libc/i386-linux-gnu/eval1.s
;; ld: cannot find crtbeginS.o: No such file or directory
;; ld: cannot find -lgcc: No such file or directory
;; ld: cannot find -lgcc_s: No such file or directory
;; ld: skipping incompatible /gnu/store/hw6g2kjayxnqi8rwpnmpraalxi0djkxc-glibc-2.39/lib/libc.so when searching for -lc
;; ld: cannot find -lc: No such file or directory
;; ld: skipping incompatible /gnu/store/hw6g2kjayxnqi8rwpnmpraalxi0djkxc-glibc-2.39/lib/libc.so when searching for -lc
;; ld: cannot find -lgcc: No such file or directory
;; ld: cannot find -lgcc_s: No such file or directory
;; ld: cannot find crtendS.o: No such file or directory

(use-modules
 (gnu packages llvm)
 (gnu packages commencement)
 (guix)
 (guix profiles)
 (guix packages))

(define (cross-package-entry pkg target-triplet)
  (manifest-entry
    (inherit (package->manifest-entry pkg))
    (item
     (with-parameters ((%current-target-system target-triplet))
       pkg))))

(manifest
 (append
   ;; you can pick specific version-classes here
  (map package->manifest-entry
       (list
        clang-toolchain-21              ; use a specific version
        ;; clang-toolchain                 ; use whatever is in guix (usually old)
        ;; gcc-toolchain
        ))

  ;; This works, but the header file alone is not enough to compile to i686.
  ;; (list (cross-package-entry glibc "i686-linux-gnu"))

  ;; get the latest from the channels you have `guix pull`ed
  (manifest-entries
   (specifications->manifest
    '("coreutils"
      "diffutils"
      ;;"clang-toolchain"
      "glibc"
      "glibc:debug"
      ;; "libffi"
      "make"
      "time"
      "ncurses"        ; for clear, reset, tput (used by the Makefile)
      "git"
      "findutils"                       ; find is used in the Makefile

      ;;
      ;; the rest is only for convenience
      ;;
      "perf"
      "bash-completion"
      "gawk"
      "sed"
      "git:gui"
      "man-pages"
      "less"
      "gdb"
      "cgdb"
      "cutter"
      "intel-xed" ; for authoritative disassembling
      )))))
