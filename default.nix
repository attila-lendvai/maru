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
      #libffi.dev
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

  # TODO this doesn't work: make TARGET_CPU=i686 TARGET_VENDOR=linux TARGET_OS=gnu test-bootstrap-llvm eval-llvm || beep
  # https://github.com/NixOS/nixpkgs/issues/36947
  # Programs should be finding it from ${gcc.lib}/lib/libgcc.so
  #
  # NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgsi686Linux; [
  #   libgcc.out
  # ]);
  #NIX_LDFLAGS_FOR_TARGET = "-L ${pkgsi686Linux.libgcc.out}/lib/ -L ${pkgsi686Linux.glibc.out}/lib/";
  #NIX_LDFLAGS_FOR_TARGET = "-L ${pkgs.clang_multi.out}/lib/";
  #NIX_LDFLAGS = "-L ${pkgsi686Linux.clang.out}/lib/";

  buildCommand = ''
    make test-bootstrap
  '';

  shellHook = ''
    alias beep='(${pkgs.pulseaudio.out}/bin/paplay ${pkgs.gnome3.gnome-control-center.out}/share/sounds/gnome/default/alerts/glass.ogg &)'
    alias ..='cd ..'
    alias ...='cd ../..'
  '';
}
