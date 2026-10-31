#!/bin/sh
#
# Ubuntu dependencies used by CI. Debian derivatives may need a different
# CLANG_VERSION. This is the package list the CI image is built from.

set -eu

apt_flags=
case "${1:-}" in
    --no-install-recommends)	apt_flags=--no-install-recommends ;;
    "")				;;
    *)				echo "usage: $0 [--no-install-recommends]" >&2; exit 2 ;;
esac

if [ "$(id -u)" != 0 ]; then
    echo "run as root: sudo $0" >&2
    exit 1
fi

clang_version="${CLANG_VERSION:-22}"

common_packages="
  bash make git rsync time less strace rlwrap
  llvm clang-$clang_version lld libc6-dev libffi-dev
  binutils binutils-x86-64-linux-gnu binutils-aarch64-linux-gnu
  diffoscope musl musl-dev
  qemu-user qemu-user-binfmt
  wget curl ca-certificates gnupg lsb-release software-properties-common
"

# target/arch=i686 only
i686_packages="
  binutils-i686-linux-gnu
  gcc-i686-linux-gnu
  libc6-dev-i386-cross
"

case "$(dpkg --print-architecture)" in
    amd64)
	cross_packages="gcc-aarch64-linux-gnu libc6-dev-arm64-cross"
	i686_packages="$i686_packages libc6-dev-i386"	# native 32-bit runtime
	;;
    arm64)
	cross_packages="gcc-x86-64-linux-gnu libc6-dev-amd64-cross"
	;;
    *)
	echo "unsupported host architecture: $(dpkg --print-architecture)" >&2
	exit 1
	;;
esac

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"

apt-get update
# shellcheck disable=SC2086 # intentional word splitting
apt-get install -y $apt_flags $common_packages $cross_packages $i686_packages

update-alternatives --install /usr/bin/clang clang "/usr/bin/clang-$clang_version" 100
update-alternatives --install /usr/bin/clang++ clang++ "/usr/bin/clang++-$clang_version" 100
update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100
update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100
