# CI: bootstrap through musl libc

Goal: test that maru can bootstrap with musl's ELF interpreter instead of
glibc's.

## Background (verified in the repo)

- The `linux` platform binaries from the x86/arm backends embed a PT_INTERP
  with `+ld.so-path+` (build.l:485 -> emit-x86.l:1572, emit-arm.l:1731).
- `ld.so=...` on the build.sh command line sets the global (build.l:867),
  `effective-ld.so` honors it (build.l:261-283), and it is listed in
  `*input-variables-for-build*` (build.l:180) so caches invalidate.
- Bootstrap executes eval0/eval1/eval2, so the whole ladder really runs
  under musl's loader; success = byte-identical eval1 == eval2.
- Only the native backends honor ld.so. llvm+linux links statically
  (`-Wl,-Bstatic,-no-pie`, build.l:315), so an llvm run would silently not
  exercise musl.
- Ubuntu noble's `musl` package ships `/lib/ld-musl-x86_64.so.1`
  (and `musl-dev` the headers); confirmed via packages.ubuntu.com file list.

## Changes

### tools-for-build/Dockerfile.ci

Add to the main apt list, after `ca-certificates`:

```
        musl \
        musl-dev \
```

### .github/workflows/ci.yaml

In `build-linux-amd64`, right after `- run: timeout 5m ./build.sh bootstrap x86  linux`:

```yaml
      # the self-contained x86 binaries are mapped/run through musl's
      # ELF interpreter instead of glibc's
      - run:  timeout 5m ./build.sh ld.so=/lib/ld-musl-x86_64.so.1 bootstrap x86 linux
```

In `build-linux-arm64`, right after `- run: timeout 5m ./build.sh bootstrap llvm linux`:

```yaml
      - run:  timeout 5m ./build.sh ld.so=/lib/ld-musl-aarch64.so.1 bootstrap arm linux
```

## Follow-up (manual, outside the repo)

The workflows consume prebuilt ghcr.io images; nothing builds them in CI.
Rebuild and push both variants before running CI (commands are in the
Dockerfile.ci header comments):

    podman build --platform linux/amd64 -t ghcr.io/attila-lendvai/maru-ci:amd64 \
      --build-arg CI_IMAGE_VERSION=$(date --rfc-3339 date) -f Dockerfile.ci .
    podman push ghcr.io/attila-lendvai/maru-ci:amd64
    podman build --platform linux/arm64 -t ghcr.io/attila-lendvai/maru-ci:arm64 \
      --build-arg CI_IMAGE_VERSION=$(date --rfc-3339 date) -f Dockerfile.ci .
    podman push ghcr.io/attila-lendvai/maru-ci:arm64

Otherwise the new steps fail with a missing `/lib/ld-musl-*.so.1`.
