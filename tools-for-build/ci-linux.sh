#!/usr/bin/env bash
#
# Run the Linux CI matrix. Run it as-is: outside the CI image it
# re-execs itself in the matching podman image. Set CI_IMAGE_VERSION
# to run inside the current (CI) container instead.
#
# Modes: --native (host arch), --cross (aarch64 from x86-64), --all.
# Default is --all. The matrix runs on a snapshot in /tmp/ci-maru, so
# the working tree is left alone. BUILD_TIMEOUT overrides the per-command
# timeout (default 5m).

set -euE

SCRIPT_NAME=$(basename "$0")

mode=all
case "${1:-}" in
    --native)	mode=native ;;
    --cross)	mode=cross ;;
    --all)	mode=all ;;
    "")		mode=all ;;
    *)		echo "usage: $0 [--native|--cross|--all]" >&2; exit 2 ;;
esac

if [ -z "${CI_IMAGE_VERSION:-}" ]; then
    cd "$(readlink -f "$(dirname "$0")")/.."
    case "$(uname -m)" in
	x86_64|i686|i386)	image=ghcr.io/attila-lendvai/maru-ci:amd64 ;;
	aarch64|arm64)		image=ghcr.io/attila-lendvai/maru-ci:arm64 ;;
	*)			echo "unsupported host arch: $(uname -m)" >&2; exit 1 ;;
    esac
    echo "Starting $image"
    # --tty only when interactive, else podman fails from a pipe
    tty_flag=
    if [ -t 0 ]; then tty_flag=--tty; fi
    exec podman run $tty_flag --rm --interactive \
	--volume "$(pwd)":/workspace --workdir /workspace \
	"$image" /bin/bash -c \
	"cp tools-for-build/$SCRIPT_NAME /tmp/ci-script && exec /tmp/ci-script --$mode"
fi

echo "$SCRIPT_NAME is running inside the container, CI_IMAGE_VERSION=$CI_IMAGE_VERSION"
export TERM="${TERM:-xterm}"

trap 'echo "Interrupted"; exit 130' INT TERM

on_error() {
    # A debug shell makes no sense without a terminal; CI must just fail.
    if [ -t 0 ]; then
	echo "*** CI failed; entering debug shell ***"
	exec /bin/bash
    fi
    exit 1
}
trap on_error ERR

git config --global --add safe.directory "$(pwd)"

echo "===== system ====="
uname -a
getconf PAGE_SIZE || true
if command -v lsb_release >/dev/null; then
    lsb_release -a || true
else
    cat /etc/os-release
fi
echo "===== tools ====="
clang --version || true
cc --version || true
ld.lld --version || true

orig=$(pwd)
dir=/tmp/ci-maru

cleanup() {
    status=$?
    cd /
    rm -rf "$dir"
    git -C "$orig" worktree prune || true
    exit "$status"
}
trap cleanup EXIT

# Snapshot the working tree (minus ignored files) so the local tree
# stays clean. The .git symlink is what lets build.sh add its host
# worktree, hence the prune on exit.
rm -rf "$dir"
mkdir -p "$dir"
git ls-files --cached --others --exclude-standard -z |
    rsync -a --from0 --files-from=- ./ "$dir/"
ln -s "$orig/.git" "$dir/.git"
git config --global --add safe.directory "$dir"
cd "$dir"

# make sure checked-in artifacts are newer than their dependencies
test -d build/ && find build/ -type f -exec touch '{}' + || true

BUILD_TIMEOUT="${BUILD_TIMEOUT:-5m}"
summary_file="${GITHUB_STEP_SUMMARY:-/dev/null}"

printf '### CI matrix\n\n| Step | Result | Time |\n|:-----|:-------|-----:|\n' \
    >> "$summary_file"

step() {
    local name="./build.sh $*"
    local start=$SECONDS
    local status
    local result=ok

    echo "::group::$name"
    timeout "$BUILD_TIMEOUT" ./build.sh "$@" && status=0 || status=$?
    echo "::endgroup::"

    if [ "$status" -ne 0 ]; then result="failed ($status)"; fi
    printf '| %s | %s | %ss |\n' "$name" "$result" "$((SECONDS - start))" \
	>> "$summary_file"

    return "$status"
}

native_amd64() {
    # test-compiler first: it fails faster than a full bootstrap
    step target/arch=i686 test-compiler x86 linux
    step target/arch=i686 test-compiler x86 posix
    step C-obj/link-type=static test-compiler x86 libc

    step bootstrap llvm linux
    step bootstrap llvm posix
    step bootstrap llvm libc

    step bootstrap x86 linux
    step bootstrap x86 posix
    step bootstrap x86 libc

    step target/arch=i686 bootstrap llvm linux
    step target/arch=i686 bootstrap llvm posix
    step target/arch=i686 bootstrap llvm libc

    step target/arch=i686 bootstrap x86 linux
    step target/arch=i686 bootstrap x86 posix
    step target/arch=i686 bootstrap x86 libc

    # the self-contained x86 binaries are mapped/run through musl's
    # ELF interpreter instead of glibc's
    step ld.so=/lib/ld-musl-x86_64.so.1 bootstrap x86 linux

    step profiler=1 bootstrap llvm posix
    step profiler=1 bootstrap llvm linux

    step test

    # *safety* set to 3. Restore boot.l by hand: a `git reset` would
    # clobber the index behind the .git symlink.
    cp boot.l boot.l.orig
    sed -i 's/(define \*safety\* 1)/(define \*safety\* 3)/' boot.l
    step bootstrap llvm linux
    step bootstrap x86 linux
    mv boot.l.orig boot.l
}

native_arm64() {
    step test-compiler arm libc

    step bootstrap llvm libc
    step bootstrap llvm posix
    step bootstrap llvm linux

    step bootstrap arm linux
    step bootstrap arm posix
    step bootstrap arm libc

    step ld.so=/lib/ld-musl-aarch64.so.1 bootstrap arm linux

    step profiler=1 bootstrap llvm posix
    step profiler=1 bootstrap llvm linux

    step test
}

cross_aarch64() {
    step target/arch=aarch64 bootstrap arm linux
    step target/arch=aarch64 bootstrap arm posix
    step target/arch=aarch64 bootstrap arm libc

    step target/arch=aarch64 bootstrap llvm linux
    step target/arch=aarch64 bootstrap llvm posix
    step target/arch=aarch64 bootstrap llvm libc
}

echo CI begins

host_arch=$(dpkg --print-architecture)
case "$host_arch" in
    amd64)
	case "$mode" in
	    native)	native_amd64 ;;
	    cross)	cross_aarch64 ;;
	    all)	native_amd64; cross_aarch64 ;;
	esac
	;;
    arm64)
	case "$mode" in
	    native|all)	native_arm64 ;;
	    cross)	echo "no cross matrix on arm64" >&2; exit 1 ;;
	esac
	;;
    *)
	echo "unsupported host architecture: $host_arch" >&2
	exit 1
	;;
esac

echo CI finished
