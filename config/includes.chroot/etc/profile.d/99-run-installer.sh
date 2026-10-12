#!/bin/sh
MARKER=/run/install-debian.ran
if [ ! -e "$MARKER" ]; then
	if grep -qw run-installer /proc/cmdline 2>/dev/null; then
		touch "$MARKER"
		sudo /usr/local/sbin/install-debian
	fi
fi
