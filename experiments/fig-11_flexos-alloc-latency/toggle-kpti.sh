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

function prompt {
	while true; do
		read -p "This script is going $1 KPTI on this machine, which requires a reboot. Proceed? [y/n] " yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) exit 1;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

function off {
	checks

	if grep -Fxq "pti=off" $GRUB_FILE; then
		die "[E] KPTI is already disabled."
	fi

	if grep -Fxq "nopti" $GRUB_FILE; then
		die "[E] KPTI is already disabled."
	fi

	prompt "disable"

	echo -n "[I] Editing kernel command line..."
	sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"pti=off /g" $GRUB_FILE

	if grep -Fxq "pti=off" $GRUB_FILE; then
		echo " done."
	else
		die "\n[E] Failed to edit kernel command line."
	fi

	# TODO print the new command line

	echo "[I] Reconfiguring GRUB..."
	update-grub

	echo "[W] Rebooting in 3s..."
	sleep 3
	reboot
}

function on {
	checks

	if grep -Fxq "pti=on" $GRUB_FILE; then
		die "[E] KPTI is already enabled."
	fi

	if ! grep -Fxq "nopti" $GRUB_FILE; then
		if ! grep -Fxq "pti=off" $GRUB_FILE; then
			die "[E] KPTI is already enabled."
		fi
	fi

	prompt "enable"

	echo "[I] Editing kernel command line..."
	sed -i "s/pti=off//g" $GRUB_FILE
	sed -i "s/nopti//g" $GRUB_FILE

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
