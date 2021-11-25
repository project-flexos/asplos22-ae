#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

GRUB_FILE="/etc/default/grub"

set -e

die() { echo "$*" 1>&2 ; exit 1; }

function disclaimer {
	echo "[I] Disclaimer:"
	echo "[I] This script is experimental. It is known to work on the official"
	echo "[I] AE setup for the FlexOS paper, but might not be entirely generic."
	echo "[I] Use at your own risk!"
	echo ""
}

function checks {
	disclaimer
	users=$(who | wc -l)
	if [ $users -ge 1 ]; then
		die "[E] Cannot toggle KPTI: there are $users logged in; please coordinate on machine use."
	fi

	if test -f "$GRUB_FILE"; then
		die "[E] This machine does not seem to use GRUB, but this script only supports GRUB."
	fi
}

function on {
	checks
	echo "[I] Editing kernel command line..."
	sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"pti=off /g" $GRUB_FILE
	# TODO check that pti=off is now present in the file
	# TODO print the new command line
	echo "[I] Reconfiguring GRUB..."
	update-grub
	echo "[W] Rebooting in 3s..."
	sleep 3
	reboot
}

function off {
	checks
	echo "[I] Editing kernel command line..."
	sed -i "s/pti=off//g" $GRUB_FILE
	echo "[I] Reconfiguring GRUB..."
	update-grub
	echo "[W] Rebooting in 3s..."
	sleep 3
	reboot
}

case "$1" in
    on)
        on
        ;;
    off)
        off
        ;;
    *)
        die "'$1': unsupported argument. Usage: $0 {on, off}"
        ;;
esac
