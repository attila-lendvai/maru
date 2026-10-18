# Self-reproducing compiler-payload experiment

The experiment succeeded and is now integrated into `build.sh compiler-image`.
Use `compiler-image --self PREVIOUS OUTPUT` for each subsequent generation.
`tools-for-build/test-compiler-image.sh SEED` verifies three generations, LLVM and
stripped binary equality, and source-free REPL operation.
Artifacts were preserved in build/compiler-generations (original paths in helper
scripts may still reference /tmp/maru-generations).

Initial setup used Python once to assemble a seed image. After maru0 existed,
generations 1, 2 and 3 used only the previous image, its embedded Maru generator,
generated candidate-vm.l, shell orchestration and external clang/linker. No Python
or external compiler-source tree was used for these subsequent generations.

Each image embeds 57 baseline sources plus image/generate.l, image/manifest.l,
image/vm-template.l and image/eval.l. The template contains a payload-table marker;
the Maru generator writes its table from the image-source primitive, avoiding
recursive source expansion. The evaluator input loads generated candidate-vm.l.

Results:
- maru0 -> maru1 -> maru2 -> maru3 compiled successfully.
- Successive LLVM files are identical.
- maru1/2/3 stripped binary SHA-256:
  ee368070fce7e058ab9de39ace6f587368a5963cc087e0dd2d7ea050a873f716
- DLM: 15 assertions passed on maru3.
- Revision test: a Maru patch modified image/eval.l, inserting image-revision
  returning 69 before vm-late.l registration. Both emitted target source and
  embedded payload were changed. maru4 returned 69.
- maru4 then generated maru5 without reapplying the patch. maru5 returned 69,
  maru4.ll == maru5.ll, and 15 DLM assertions passed on maru5.

The integrated generator is tools-for-build/self-image-generator.l. It uses the
image-source primitive, embedded manifest and loader template. Python assembles
only the initial image; subsequent --self builds execute this Maru generator.

Limits: LLVM/Linux/x86-64 only, selected fixed source closure, manual patching,
external shell/clang/linker, no general source override interface or autonomous
DLM compiler improvement. Generation is self-reproducing but compiler correctness
and arbitrary future modifications are not established by fixed-point equality.
