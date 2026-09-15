#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess
import libcalamares

# Lines of captured command output to keep in an error message.
OUTPUT_TAIL = 40

def run_command(args, name, env=None, stdin=None):
    libcalamares.utils.debug("{}: running {}".format(name, args))
    result = subprocess.run(args, capture_output=True, text=True, env=env, stdin=stdin)
    if result.returncode != 0:
        output = (result.stderr or result.stdout or "(no output)").strip()
        tail = "\n".join(output.splitlines()[-OUTPUT_TAIL:])
        raise RuntimeError("`{}` failed (exit {}):\n{}".format(
            " ".join(args), result.returncode, tail))
    return result.stdout


def run_job(name, do_run):
    try:
        do_run()
    except Exception as e:
        libcalamares.utils.warning("{} failed: {}".format(name, e))
        return ("{} failed".format(name), str(e))
    return None
