{ pkgs ? import <nixpkgs> {} }:

# https://nixos.wiki/wiki/Packaging/32bit_Applications
#pkgs.mkShell {
#multiStdenv.mkDerivation {
pkgs.pkgsi686Linux.stdenv.mkDerivation {
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
    export BEEP=/result/sw/share/sounds/gnome/default/alerts/glass.ogg
    alias beep='(paplay $BEEP &)'
    alias ..='cd ..'
    alias ...='cd ../..'
  '';
}
