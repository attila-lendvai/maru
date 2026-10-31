# run from tools-for-build/ (the context must contain install-ubuntu-deps.sh)
# podman build --platform linux/amd64 -t ghcr.io/attila-lendvai/maru-ci:amd64 --build-arg CI_IMAGE_VERSION=$(date --rfc-3339 date) -f Dockerfile .
# podman build --platform linux/arm64 -t ghcr.io/attila-lendvai/maru-ci:arm64 --build-arg CI_IMAGE_VERSION=$(date --rfc-3339 date) -f Dockerfile .

# need to log in with a token generated at: https://github.com/settings/tokens
# podman login ghcr.io -u attila-lendvai

# podman push ghcr.io/attila-lendvai/maru-ci:amd64
# podman push ghcr.io/attila-lendvai/maru-ci:arm64

# for the first time go to:
# https://github.com/attila-lendvai?tab=packages&ecosystem=container
# and make it public in the package settings

# shell into the image
# podman run  --tty --rm --interactive --volume "$(pwd)":/workspace --workdir /workspace ghcr.io/attila-lendvai/maru-ci:amd64 /bin/bash

FROM docker.io/ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGETARCH

ARG CI_IMAGE_VERSION=dev
ENV CI_IMAGE_VERSION=$CI_IMAGE_VERSION

RUN echo TARGETARCH="$TARGETARCH"
RUN echo CI_IMAGE_VERSION="$CI_IMAGE_VERSION"

# Conditional packages per host arch: the cross gcc's of the foreign
# targets. clang needs them for its gcc installation detection to find
# crtbegin et al (the native libgcc comes with clang itself). build.l
# points clang at the cross sysroot /usr/<triple> that they provide
# (clang does not adopt it on its own). NB: the cross libc-dev packages
# are only Recommends, so they must stay explicit under
# --no-install-recommends.
COPY install-ubuntu-deps.sh /tmp/
RUN /tmp/install-ubuntu-deps.sh --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# if/when we need the latest llvm...
# RUN curl -fsSL https://apt.llvm.org/llvm.sh -o llvm.sh && chmod +x llvm.sh && ./llvm.sh 23

# Ensure bash is the default shell
# SHELL ["/bin/bash", "-c"]

# Enable bash-completion for root
RUN echo 'if [ -f /usr/share/bash-completion/bash_completion ]; then' >> /root/.bashrc \
 && echo '  . /usr/share/bash-completion/bash_completion' >> /root/.bashrc \
 && echo 'fi' >> /root/.bashrc >> /root/.bashrc

# This is needed to avoid a git warning:
# fatal: detected dubious ownership in repository at '/workspace'
RUN git config --global --add safe.directory /workspace

WORKDIR /workspace
