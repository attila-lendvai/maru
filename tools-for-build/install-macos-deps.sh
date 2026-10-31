#!/bin/sh
#
# macOS dependencies used by CI. Requires XCode and Homebrew.

set -eu

if ! command -v brew >/dev/null; then
    echo "Homebrew is required: https://brew.sh" >&2
    exit 1
fi

brew install llvm coreutils rlwrap
