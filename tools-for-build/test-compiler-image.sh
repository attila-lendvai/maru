#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEED="${1:-$ROOT/build/llvm-linux/x86_64-unknown-linux-gnu/eval1}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
"$ROOT/build.sh" compiler-image "$SEED" "$WORK/image0"
for n in 1 2 3; do
 previous=$((n - 1))
 "$ROOT/build.sh" compiler-image --self "$WORK/image$previous" "$WORK/image$n"
 cmp "$WORK/image$previous.ll" "$WORK/image$n.ll"
 cp "$WORK/image$n" "$WORK/image$n.stripped"
 strip "$WORK/image$n.stripped"
done
cmp "$WORK/image1.stripped" "$WORK/image2.stripped"
cmp "$WORK/image2.stripped" "$WORK/image3.stripped"
mkdir "$WORK/empty"
(cd "$WORK/empty"; printf '(+ 1 2)\n' | "$WORK/image3" boot.l -) > "$WORK/repl.log"
grep -q 'maru> 3' "$WORK/repl.log"
echo 'PASS: three self-image generations, LLVM/binary fixed point and source-free REPL'
