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
 (guix packages)
 (guix build-system gnu)
 )

(define (binutils-prefixed target-triplet)
  (let ((pkg (package
              (inherit binutils)
              (name (string-append "binutils-prefixed-" target-triplet))
              (arguments
               (substitute-keyword-arguments
                (package-arguments binutils)
                ((#:configure-flags flags #~'())
                 #~(cons #$(string-append "--program-prefix="
                                          target-triplet
                                          "-")
                         #$flags)))))))
    (manifest-entry
     (inherit (package->manifest-entry pkg))
     (item
      (with-parameters ((%current-target-system target-triplet))
        pkg)))))

(manifest
 (append

  ;; you can pick specific version-classes here
  (map package->manifest-entry
       (list
        clang-toolchain-21              ; use a specific version
        lld-21  ; can cross-compile; clang-toolchain comes with GNU ld
        ;; clang-toolchain                 ; use whatever is in guix (usually old)
        ;; gcc-toolchain
        ))

  ;; This works, but the header file alone is not enough to compile to i686.
  ;; (list (cross-package-entry glibc "i686-linux-gnu"))

  ;; this leads to an attempt to compile it locally but fails with:
  ;; objcopy: Unable to recognise the format of the input file `/tmp/guix-build-glibc-2.41.drv-0/build/libc_pic.os'
  ;; there's this, too (cross-clang): https://issues.guix.gnu.org/54239
  ;; (list (cross-package-entry glibc "aarch64-linux-gnu"))

  (list
   ;; these are needed for the assembler tests. by making the prefixes
   ;; explicit, it works transparently in the x86 and arm CI runners.
   (binutils-prefixed "aarch64-linux-gnu")
   (binutils-prefixed "x86_64-linux-gnu"))

  ;; get the latest from the channels you have `guix pull`ed
  (manifest-entries
   (specifications->manifest
    '("coreutils"
      "nss-certs" ; so that git pull works on OpenWrt
      "diffutils"
      "diffoscope"
      ;;"clang-toolchain"
      "glibc"
      "glibc:debug"
      "libffi"                          ; for the c99 implementations
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
      "qemu"
      "intel-xed"                    ; for authoritative disassembling
      )))))
