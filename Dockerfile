FROM debian:trixie-slim

# Install required tools for live ISO creation and system setup
RUN apt-get update && apt-get install -y --no-install-recommends \
    live-build \
    debootstrap \
    sudo \
    wget \
    curl \
    systemd-sysv \
    openssh-server \
    cryptsetup \
    lvm2 \
    btrfs-progs \
    fdisk \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-utils \
    rsync \
    git \
    psmisc \
    e2fsprogs \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /build
