#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import functools
import os
import shutil
import subprocess
import sys

import libcalamares

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from _common import run_job  # noqa: E402
from _common import run_command as _run_command  # noqa: E402

APT_ENV = dict(os.environ, DEBIAN_FRONTEND="noninteractive")

INSTALL_PACKAGES = [
    "grub-common-", "shim-signed", "systemd-boot",
    "systemd-boot-efi-amd64-signed", "dracut", "initramfs-tools-",
    "systemd-zram-generator", "systemd-cryptsetup",
    "plymouth", "plymouth-themes",
]

run_command = functools.partial(_run_command, name="bootloader-stack-swap", stdin=subprocess.DEVNULL)

def chroot_call(root_mount_point, args):
    run_command(["chroot", root_mount_point] + args, env=APT_ENV)

def do_run():
    root_mount_point = libcalamares.globalstorage.value("rootMountPoint")

    sources_list = os.path.join(root_mount_point, "etc", "apt", "sources.list")
    if os.path.exists(sources_list):
        os.remove(sources_list)

    # Read by systemd-boot's postinst (bootctl install, kernel-install add).
    root = next(p for p in libcalamares.globalstorage.value("partitions")
                if p.get("mountPoint") == "/")
    if root.get("luksUuid"):
        root_args = "rd.luks.uuid={0} root=/dev/mapper/{1}".format(
            root["luksUuid"], root["luksMapperName"])
    else:
        root_args = "root=UUID={0}".format(root["uuid"])
    kernel_dir = os.path.join(root_mount_point, "etc", "kernel")
    os.makedirs(kernel_dir, exist_ok=True)
    with open(os.path.join(kernel_dir, "entry-token"), "w") as f:
        f.write("debian\n")
    with open(os.path.join(kernel_dir, "cmdline"), "w") as f:
        f.write("{0} rootflags=subvol=@ rw quiet splash\n".format(root_args))

    # Only keep /boot/initrd.img-* (built by dracut's kernel postinst hook):
    # 50-dracut.install would add a second, kernel-install generated one.
    install_d = os.path.join(root_mount_point, "etc", "kernel", "install.d")
    os.makedirs(install_d, exist_ok=True)
    os.symlink("/dev/null", os.path.join(install_d, "50-dracut.install"))

    archives = os.path.join(root_mount_point, "var", "cache", "apt", "archives")
    os.makedirs(archives, exist_ok=True)
    run_command(["mount", "/root/deb-cache", archives, "-o", "bind"])
    try:
        chroot_call(root_mount_point, ["apt-get", "install", "-y"] + INSTALL_PACKAGES)
        chroot_call(root_mount_point, ["dpkg", "--purge", "initramfs-tools"])
        chroot_call(root_mount_point, ["apt-get", "autoremove", "-y", "--purge"])
    finally:
        subprocess.call(["umount", archives])

    shutil.rmtree(os.path.join(root_mount_point, "etc", "initramfs-tools"), ignore_errors=True)

def pretty_name():
    return "Installation de systemd-boot et de dracut."

def run():
    return run_job("bootloader-stack-swap", do_run)
