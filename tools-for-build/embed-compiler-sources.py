#!/usr/bin/env python3
"""One-time assembly of a self-reproducing compiler image's source inputs."""
import json
from pathlib import Path
import sys

root, work = map(Path, sys.argv[1:])

def quote(text):
    return '"' + text.replace('\\', '\\\\').replace('"', '\\"') + '"'

source = (root / 'source/evaluator/vm-with-file-support.l').read_text()
prefix = (root / 'tools-for-build/embedded-stream.l').read_text()
old = '''(define-vm-function (load ()) ((path <string>))
  (with-input-from-file (stream path)
    (expand-encode-eval-stream stream)))'''
new = prefix + '''
@@TABLE@@
(define-vm-function image-source ((path <string>))
  (let ((text (embedded-source (string->C-string path))))
    (or text (error "no image source: " path))))

(define-vm-function (load ()) ((path <string>))
  (let ((payload (embedded-source (string->C-string path))))
    (if payload
        (gc/let* ((stream (embedded-stream payload)))
          (expand-encode-eval-stream stream))
      (with-input-from-file (stream path)
        (expand-encode-eval-stream stream)))))

(define-function embedded-or-file-repl (path)
  (let ((payload (embedded-source (string->C-string path))))
    (if payload
        (gc/let* ((stream (embedded-stream payload)))
          (repl-stream stream *standard-output* false))
      (with-input-from-file (stream path)
        (repl-stream stream *standard-output* false)))))'''
old_cli = '''(with-input-from-file (stream arg)
                 (set exit-code (unbox <long> (repl-stream stream *standard-output* false)))'''
new_cli = '''(let ()
                 (set exit-code (unbox <long> (embedded-or-file-repl arg)))'''
assert source.count(old) == source.count(old_cli) == 1, 'upstream loader changed'
image = work / 'image'
image.mkdir()
(image / 'generate.l').write_text((root / 'tools-for-build/self-image-generator.l').read_text())
(image / 'vm-template.l').write_text(source.replace(old_cli, new_cli).replace(old, new))
(image / 'eval.l').write_text((root / 'source/platforms/linux/eval.l').read_text().replace(
    'source/evaluator/vm-with-file-support.l', 'candidate-vm.l'))
files = [Path('boot.l'), *sorted(p.relative_to(root) for p in (root / 'source').rglob('*.l')),
         *[Path('image') / f for f in ('generate.l', 'manifest.l', 'vm-template.l', 'eval.l')]]
(image / 'manifest.l').write_text('(define *image-files* (list ' +
    ' '.join(quote(str(p)) for p in files) + '))\n')
table = '(define-function embedded-source (path)\n  (cond\n'
for rel in files:
    table += '    ((embedded-path=? path ' + quote(str(rel)) + ') ' + quote(
        (work / rel).read_text()) + ')\n'
table += '    (else 0)))\n'
(work / 'candidate-vm.l').write_text((image / 'vm-template.l').read_text().replace('@@TABLE@@', table))
(work / 'payload-manifest.json').write_text(json.dumps([str(p) for p in files], indent=2))
print(f'Embedded {len(files)} source/template/generator files')
