{ pkgs            ? import <nixpkgs> {},
  pkgsx86_64Linux ? import <nixpkgs> { system = "x86_64-linux"; },
  pkgsi686Linux   ? import <nixpkgs> { system = "i686-linux"; }
}:

# https://nixos.wiki/wiki/Packaging/32bit_Applications
#pkgs.mkShell {
#pkgs.stdenv.mkDerivation {
#pkgsi686Linux.stdenv.mkDerivation {
#pkgs.clangMultiStdenv.mkDerivation {
pkgs.multiStdenv.mkDerivation {
  name = "maru";

  buildInputs = with pkgs;
    [
      coreutils time ncurses posix_man_pages bash-completion less
      #lorri direnv
      gitFull diffutils
      gnumake
      libffi.dev
      gdb binutils
      llvm_11 clang_11
      #clang
      #clang_multi
      #clang_multi.out
      #pkgsi686Linux.libgcc.out
      #pkgsi686Linux.clang.out
      #gcc
      #glibc_multi.out

      # keep this line if you use bash
      bashInteractive
    ];

  buildCommand = ''
    make test-bootstrap
  '';

  shellHook = ''
    alias beep='(${pkgs.pulseaudio.out}/bin/paplay ${pkgs.gnome3.gnome-control-center.out}/share/sounds/gnome/default/alerts/glass.ogg &)'
    alias ..='cd ..'
    alias ...='cd ../..'
  '';
}
