#!/usr/bin/env bash
#
# Run the macOS CI matrix. Run install-macos-deps.sh first.
# BUILD_TIMEOUT overrides the per-command timeout (default 3m).

set -eu

cd "$(dirname "$0")/.."

export TERM="${TERM:-xterm}"
# Homebrew's clang config pins the CLT SDK; use the active SDK instead,
# as Apple clang does. See the comment in the old workflow.
export CLANG_NO_DEFAULT_CONFIG=1
export PATH="$(brew --prefix llvm)/bin:$(brew --prefix coreutils)/bin:$PATH"
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"

git config --global --add safe.directory "$(pwd)"

echo "===== system ====="
uname -a
sw_vers || true
uname -m
echo "===== tools ====="
clang --version || true
cc --version || true
ld.lld --version || true

# make sure checked-in artifacts are newer than their dependencies
test -d build/ && find build/ -type f -exec touch '{}' + || true

BUILD_TIMEOUT="${BUILD_TIMEOUT:-3m}"
summary_file="${GITHUB_STEP_SUMMARY:-/dev/null}"

printf '### CI matrix\n\n| Step | Result | Time |\n|:-----|:-------|-----:|\n' \
    >> "$summary_file"

run_build() {
    local cmd=(./build.sh "$@")
    # force the arm64 slice on universal binaries
    if [ "$(uname -m)" = arm64 ]; then cmd=(arch -arm64 "${cmd[@]}"); fi

    local name="${cmd[*]}"
    local start=$SECONDS
    local status
    local result=ok

    echo "::group::$name"
    if command -v timeout >/dev/null; then
	timeout "$BUILD_TIMEOUT" "${cmd[@]}" && status=0 || status=$?
    elif command -v gtimeout >/dev/null; then
	gtimeout "$BUILD_TIMEOUT" "${cmd[@]}" && status=0 || status=$?
    else
	"${cmd[@]}" && status=0 || status=$?
    fi
    echo "::endgroup::"

    if [ "$status" -ne 0 ]; then result="failed ($status)"; fi
    printf '| %s | %s | %ss |\n' "$name" "$result" "$((SECONDS - start))" \
	>> "$summary_file"

    return "$status"
}

echo CI begins

run_build bootstrap llvm libc
run_build bootstrap llvm posix
run_build profiler=1 bootstrap llvm posix
run_build test

echo CI finished
