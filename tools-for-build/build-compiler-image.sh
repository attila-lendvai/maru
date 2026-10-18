#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SELF=false
if [[ "${1:-}" == --self ]]; then SELF=true; shift; fi
SEED="${1:-$ROOT/build/llvm-linux/x86_64-unknown-linux-gnu/eval1}"
OUT="${2:-$ROOT/build/compiler-image/maru-compiler}"
SEED="$(realpath "$SEED")"
OUT="$(realpath -m "$OUT")"
[[ -x "$SEED" ]] || { echo "Missing executable seed: $SEED" >&2; exit 1; }
command -v clang >/dev/null
if [[ "$SELF" == false ]]; then command -v python3 >/dev/null; fi
mkdir -p "$(dirname "$OUT")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
if [[ "$SELF" == false ]]; then
  cp -a "$ROOT/source" "$WORK/source"
  cp "$ROOT/boot.l" "$WORK/boot.l"
  python3 "$ROOT/tools-for-build/embed-compiler-sources.py" "$ROOT" "$WORK"
fi
cd "$WORK"
if [[ "$SELF" == true ]]; then
  "$SEED" boot.l image/generate.l
fi
"$SEED" -O \
 --define '*host-directory*' "$WORK" --define '*slave-directory*' "$WORK" \
 --define '*compiler-backend*' llvm \
 --define target/arch x86_64 --define target/vendor unknown \
 --define target/os linux --define target/abi gnu --define target/platform linux \
 --define feature/profiler/build false \
 --define '+ld.so-path+' /lib64/ld-linux-x86-64.so.2 --define elf-emission-type '' \
 source/bootstrapping/prepare.l boot.l source/bootstrapping/host-ready.l \
 source/bootstrapping/early.l boot.l source/bootstrapping/late.l \
 source/platforms/load-platform.l image/eval.l \
 source/platforms/run-compiler.l "$WORK/compiler.ll"
clang -O3 -fPIE -nostdlib -nostartfiles -ffreestanding \
 -Wl,-Bstatic,-no-pie -Qunused-arguments "$WORK/compiler.ll" -o "$WORK/compiler"
cp "$WORK/compiler" "$OUT.new"
mv "$OUT.new" "$OUT"
cp "$WORK/compiler.ll" "$OUT.ll"
if [[ -f "$WORK/payload-manifest.json" ]]; then
  cp "$WORK/payload-manifest.json" "$OUT.payloads.json"
fi
echo "Built compiler-source image: $OUT"
echo 'Self-reproducing compiler-source image; compiler Lisp executes through the evaluator.'
