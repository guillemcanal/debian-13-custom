#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Mount at /run/calamares-source what "unpackfs" copies (it can't choose its
# source based on the user's selection): the base filesystem, with the desktop
# layer picked in packagechooser on top, if any. As in install-debian, a
# read-only overlay applies the desktop layer's whiteouts (files its install
# removed) instead of copying them as device nodes.
import os
import subprocess
import sys

import libcalamares

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from _common import run_command, run_job  # noqa: E402

BASE_SQUASHFS = "/run/live/medium/live/filesystem.squashfs"
DESKTOP_SQUASHFS = "/run/live/medium/desktops/{}-desktop.squashfs"
SOURCE = "/run/calamares-source"
BASE_MOUNT = "/run/calamares-layers/base"
DESKTOP_MOUNT = "/run/calamares-layers/desktop"

# packagechooser's default instance id (this is the only packagechooser
# module in the sequence) — see modules/packagechooser.conf.
DESKTOP_GS_KEY = "packagechooser_packagechooser"

def mount(args, mount_point):
    os.makedirs(mount_point, exist_ok=True)
    run_command(["mount"] + args + [mount_point], "select-desktop-image")

def do_run():
    # Empty: packagechooser's "no desktop" item.
    desktop = (libcalamares.globalstorage.value(DESKTOP_GS_KEY) or "").strip()

    # Left mounted by a previous attempt in this live session.
    for mount_point in (SOURCE, DESKTOP_MOUNT, BASE_MOUNT):
        subprocess.call(["umount", mount_point], stderr=subprocess.DEVNULL)

    if not desktop:
        mount(["-t", "squashfs", "-o", "loop,ro", BASE_SQUASHFS], SOURCE)
        return

    desktop_image = DESKTOP_SQUASHFS.format(desktop)
    if not os.path.exists(desktop_image):
        raise RuntimeError("Desktop image not found: {}".format(desktop_image))

    mount(["-t", "squashfs", "-o", "loop,ro", BASE_SQUASHFS], BASE_MOUNT)
    mount(["-t", "squashfs", "-o", "loop,ro", desktop_image], DESKTOP_MOUNT)
    mount(["-t", "overlay", "-o", "ro,lowerdir={0}:{1}".format(DESKTOP_MOUNT, BASE_MOUNT), "overlay"], SOURCE)


def pretty_name():
    return "Sélection de l'environnement de bureau."

def run():
    return run_job("select-desktop-image", do_run)
