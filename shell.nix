{ pkgs            ? import <nixpkgs> {},
  pkgsx86_64Linux ? import <nixpkgs> { system = "x86_64-linux"; },
  pkgsi686Linux   ? import <nixpkgs> { system = "i686-linux"; }
}:

# https://nixos.wiki/wiki/Packaging/32bit_Applications
#pkgs.mkShell {
#multiStdenv.mkDerivation {
pkgsi686Linux.stdenv.mkDerivation {
  name = "maru";

  buildInputs = with pkgs; [
    coreutils time ncurses posix_man_pages bash-completion less
    gitFull diffutils
    gnumake
    libffi.dev
    gcc gdb binutils
    llvm_11 clang_11

    # keep this line if you use bash
    bashInteractive
  ];

  buildCommand = ''
    make test-bootstrap
  '';

  shellHook = ''
    mkdir -p build
    # KLUDGE? or not? is there a better way?
    mkdir -p build/x86-linux/i386-linux-gnu/ \
             build/llvm-linux/x86_64-linux-gnu/ \
             build/llvm-linux/i686-linux-gnu/
    cp ${pkgsi686Linux.glibc}/lib/crt1.o build/x86-linux/i386-linux-gnu/
    cp ${pkgsi686Linux.glibc}/lib/crt1.o build/llvm-linux/i686-linux-gnu/
    cp ${pkgsx86_64Linux.glibc}/lib/crt1.o build/llvm-linux/x86_64-linux-gnu/
    #cp ${pkgsi686Linux.glibc}/lib/crti.o build/x86-linux/
    #cp ${pkgsi686Linux.glibc}/lib/crtn.o build/x86-linux/
    #cp ${pkgsi686Linux.glibc}/lib/gcrt1.o build/x86-linux/
    #cp ${pkgsi686Linux.glibc}/lib/crtbegin.o build/x86-linux/
    #cp ${pkgsi686Linux.linuxHeaders.out}/include/asm-generic/errno.h build/
    #cp ${pkgsi686Linux.uclibc}/lib/crt1.o build/
    #cp ${pkgsi686Linux.uclibc}/lib/crti.o build/
    #cp ${pkgsi686Linux.uclibc}/lib/crtn.o build/
    chmod +w build/x86-linux/i386-linux-gnu/* build/llvm-linux/x86_64-linux-gnu/* build/llvm-linux/i686-linux-gnu/*
    alias beep='(${pkgs.pulseaudio.out}/bin/paplay ${pkgs.gnome3.gnome-control-center.out}/share/sounds/gnome/default/alerts/glass.ogg &)'
    alias ..='cd ..'
    alias ...='cd ../..'
  '';
}
