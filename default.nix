with import <nixpkgs> {};

# https://nixos.wiki/wiki/Packaging/32bit_Applications
#multiStdenv.mkDerivation {
pkgsi686Linux.stdenv.mkDerivation {
  name = "maru";
  buildInputs = [ gnumake gcc gdb binutils libffi.dev
                  coreutils diffutils time ncurses
                  bash-completion less
                  gitFull
                  llvm_11 clang_11
                  posix_man_pages
                ];

  # see Makefile header for more options
  buildCommand = ''
    make test-bootstrap
  '';

  shellHook =
  ''
    export BEEP=/result/sw/share/sounds/gnome/default/alerts/glass.ogg
    alias beep='(paplay $BEEP &)'
    alias ..='cd ..'
    alias ...='cd ../..'
  '';
}
