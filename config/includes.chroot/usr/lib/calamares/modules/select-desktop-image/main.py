#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Point /run/calamares-desktop.squashfs at the desktop squashfs picked in
# packagechooser, so "unpackfs" can unpack it from a fixed path (it can't
# choose its source based on the user's selection).
import os
import sys

import libcalamares

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from _common import run_job  # noqa: E402

DESKTOP_SQUASHFS = "/run/live/medium/desktops/{}-desktop.squashfs"
DESKTOP_IMAGE_LINK = "/run/calamares-desktop.squashfs"

# packagechooser's default instance id (this is the only packagechooser
# module in the sequence) — see modules/packagechooser.conf.
DESKTOP_GS_KEY = "packagechooser_packagechooser"

def do_run():
    desktop = (libcalamares.globalstorage.value(DESKTOP_GS_KEY) or "").strip()
    if not desktop:
        raise RuntimeError("No selection in global storage key '{}'.".format(DESKTOP_GS_KEY))

    desktop_image = DESKTOP_SQUASHFS.format(desktop)
    if not os.path.exists(desktop_image):
        raise RuntimeError("Desktop image not found: {}".format(desktop_image))

    if os.path.lexists(DESKTOP_IMAGE_LINK):
        os.remove(DESKTOP_IMAGE_LINK)
    os.symlink(desktop_image, DESKTOP_IMAGE_LINK)


def pretty_name():
    return "Sélection de l'environnement de bureau."

def run():
    return run_job("select-desktop-image", do_run)
