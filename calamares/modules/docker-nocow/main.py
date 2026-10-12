#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys

import libcalamares

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from _common import run_command, run_job  # noqa: E402


def do_run():
    root_mount_point = libcalamares.globalstorage.value("rootMountPoint")
    docker_dir = os.path.join(root_mount_point, "var", "lib", "docker")

    if not os.path.ismount(docker_dir):
        raise RuntimeError(
            "{} is not a mountpoint — expected the @docker btrfs subvolume "
            "(modules/mount.conf's btrfsSubvolumes) to already be mounted there.".format(docker_dir))

    run_command(["chattr", "+C", docker_dir], "docker-nocow")

def pretty_name():
    return "Désactivation du copy-on-write pour Docker."

def run():
    return run_job("docker-nocow", do_run)
