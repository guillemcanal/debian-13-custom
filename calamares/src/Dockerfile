# Builds the modules against the Calamares the ISO installs: same Debian
# release, same backports pin (DEBIAN and BACKPORTS, see the Makefile).
ARG DEBIAN=trixie
FROM debian:${DEBIAN}-slim AS build
ARG DEBIAN
ARG BACKPORTS=true
COPY --from=archives backports.pref.chroot /etc/apt/preferences.d/backports.pref
RUN if [ "${BACKPORTS}" = true ]; then \
        echo "deb http://deb.debian.org/debian ${DEBIAN}-backports main" > /etc/apt/sources.list.d/backports.list; \
    fi \
    && apt-get update && apt-get install -y --no-install-recommends \
    calamares cmake g++ make extra-cmake-modules libkf6coreaddons-dev libyaml-cpp-dev \
    qt6-base-dev qt6-declarative-dev qt6-svg-dev qt6-tools-dev qt6-l10n-tools \
    && rm -rf /var/lib/apt/lists/*
COPY . /src
RUN cmake -S /src -B /build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
    && cmake --build /build && ctest --test-dir /build --output-on-failure \
    && DESTDIR=/out cmake --install /build

FROM scratch
COPY --from=build /out/usr/lib/x86_64-linux-gnu/calamares/modules/tpm2-state/ /
