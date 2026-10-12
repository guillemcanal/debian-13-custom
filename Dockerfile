# The live-build of the release being built (DEBIAN, see the Makefile)
ARG DEBIAN=trixie
FROM debian:${DEBIAN}-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    live-build \
    squashfs-tools \
    psmisc \
    rsync \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
