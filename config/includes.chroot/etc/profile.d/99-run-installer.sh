#!/bin/sh
MARKER=/run/install-debian.ran
if [ ! -e "$MARKER" ]; then
	if grep -qw run-installer-gui /proc/cmdline 2>/dev/null; then
		touch "$MARKER"
		LC_ALL=fr_FR.UTF-8 startx /usr/bin/calamares-install-debian -- :0
	elif grep -qw run-installer /proc/cmdline 2>/dev/null; then
		touch "$MARKER"
		sudo /usr/local/sbin/install-debian
	fi
fi
