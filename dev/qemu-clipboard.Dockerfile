# Debian's QEMU built from the trixie-backports sources, for when backports has
# no amd64 binaries yet for QEMU >= 11.1 (first version whose GTK display has
# clipboard=on). Built by `make qemu-clipboard`, see README.
FROM debian:trixie AS build

# Only the system emulators: skip tests, linux-user and the Xen build
ENV DEBIAN_FRONTEND=noninteractive \
    DEB_BUILD_PROFILES="nocheck pkg.qemu.omit-user pkg.qemu.omit-system-xen"

RUN printf 'Types: deb deb-src\nURIs: http://deb.debian.org/debian\nSuites: trixie-backports\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n' \
        > /etc/apt/sources.list.d/backports.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends build-essential

WORKDIR /src
RUN apt-get source qemu/trixie-backports
RUN cd qemu-*/ && apt-get build-dep -y ./

RUN cd qemu-*/ \
    && DEB_BUILD_OPTIONS="nocheck terse noautodbgsym parallel=$(nproc)" \
       dpkg-buildpackage -b -uc -us

FROM scratch
COPY --from=build /src/*.deb /
