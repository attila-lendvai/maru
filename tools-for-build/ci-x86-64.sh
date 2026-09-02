#!/usr/bin/env bash

# This can be used to spawn a local CI container to run this longer CI
# script. It is independent from the github CI, but it is executed in
# the same container image.
#
# It runs a snapshot of the working copy, starting from an empty
# build/ dir.

SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$0")
SCRIPT_DIR=$(readlink -f ${SCRIPT_DIR})

if ! [ -n "$CI_IMAGE_VERSION" ]; then
    # if we are run outside the image, then fire up the image to run us inside it
    echo Starting the container
    # we make a copy so that we can edit the file outside the container
    exec podman run --tty --rm --interactive --volume "$(pwd)":/workspace --workdir /workspace ghcr.io/attila-lendvai/maru-ci:amd64 /bin/bash -c "cp tools-for-build/${SCRIPT_NAME} /tmp/ci-script && exec /tmp/ci-script"
    exit 0
fi

echo ${SCRIPT_NAME} is running inside the container, CI_IMAGE_VERSION=${CI_IMAGE_VERSION}

set -eu

trap 'echo "Interrupted"; exit 130' INT TERM

trap 'echo "*** CI script failed ***; entering debug shell"; exec /bin/bash' ERR

dir=/tmp/ci-maru

# make a copy of the working dir into /tmp/ so that no one steps on
# each other's feet
mkdir $dir
# copy the working dir minus the .gitignore list
git ls-files --cached --others --exclude-standard -z |
    rsync -a --from0 --files-from=- ./ "$dir/"
ln -s $(pwd)/.git $dir/.git
cd $dir

# make sure any checked in artifacts are newer than their dependencies
test -d build/ && find build/ -type f -exec touch '{}' + || true

echo CI begins

./build.sh bootstrap llvm linux
./build.sh bootstrap llvm posix
./build.sh bootstrap llvm libc

./build.sh bootstrap x86  linux
./build.sh bootstrap x86  posix
./build.sh bootstrap x86  libc

./build.sh ld.so=/lib/ld-musl-x86_64.so.1 bootstrap x86 linux

./build.sh profiler=1 bootstrap llvm posix
./build.sh profiler=1 bootstrap llvm linux

./build.sh test

#
# Bootstrap with *safety* set to 3
#

sed -i 's/(define \*safety\* 1)/(define \*safety\* 3)/' boot.l
./build.sh bootstrap llvm linux
./build.sh bootstrap x86  linux

#
# Cross compile targets
#
git reset --hard

./build.sh target/arch=i686 bootstrap llvm posix
./build.sh target/arch=i686 bootstrap llvm libc

./build.sh target/arch=aarch64 bootstrap arm  linux
./build.sh target/arch=aarch64 bootstrap arm  posix
./build.sh target/arch=aarch64 bootstrap arm  libc

./build.sh target/arch=aarch64 bootstrap llvm linux
./build.sh target/arch=aarch64 bootstrap llvm posix
./build.sh target/arch=aarch64 bootstrap llvm libc

echo CI finished
