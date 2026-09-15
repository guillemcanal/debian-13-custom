#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys

import libcalamares

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from _common import run_command, run_job  # noqa: E402


def do_run():
    if not os.path.exists("/dev/tpmrm0"):
        libcalamares.utils.debug("tpm2-enroll: no TPM2 device, skipping")
        return

    root = next(p for p in libcalamares.globalstorage.value("partitions")
                if p.get("mountPoint") == "/")
    if not root.get("luksUuid"):
        libcalamares.utils.debug("tpm2-enroll: root is not encrypted, skipping")
        return

    root_mount_point = libcalamares.globalstorage.value("rootMountPoint")
    run_command(
        ["chroot", root_mount_point, "systemd-cryptenroll",
         "--tpm2-pcrs=secure-boot-policy+shim-policy",
         "--tpm2-device=auto", "--tpm2-pcrlock=", "--wipe-slot=tpm2",
         "/dev/disk/by-uuid/" + root["luksUuid"]],
        "tpm2-enroll",
        env=dict(os.environ, PASSWORD=root["luksPassphrase"]))

def pretty_name():
    return "Enregistrement de la clé de chiffrement dans le TPM."

def run():
    return run_job("tpm2-enroll", do_run)
