#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import shutil
import sys

import libcalamares

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from _common import run_job  # noqa: E402

WHITEOUTS_MANIFEST = "/run/live/medium/desktops/{}-desktop.whiteouts"

# packagechooser's default instance id (this is the only packagechooser
# module in the sequence) — see modules/packagechooser.conf.
DESKTOP_GS_KEY = "packagechooser_packagechooser"


def do_run():
    desktop = (libcalamares.globalstorage.value(DESKTOP_GS_KEY) or "").strip()
    if not desktop:
        raise RuntimeError("No selection in global storage key '{}'.".format(DESKTOP_GS_KEY))

    manifest = WHITEOUTS_MANIFEST.format(desktop)
    if not os.path.exists(manifest):
        raise RuntimeError("Whiteouts manifest not found: {}".format(manifest))

    root_mount_point = libcalamares.globalstorage.value("rootMountPoint")

    with open(manifest) as f:
        paths = [line.strip() for line in f if line.strip()]

    for rel in paths:
        target = os.path.join(root_mount_point, rel)
        if os.path.isdir(target) and not os.path.islink(target):
            shutil.rmtree(target, ignore_errors=True)
        else:
            try:
                os.remove(target)
            except FileNotFoundError:
                pass


def pretty_name():
    return "Nettoyage des fichiers retirés par l'environnement de bureau."

def run():
    return run_job("apply-desktop-whiteouts", do_run)
