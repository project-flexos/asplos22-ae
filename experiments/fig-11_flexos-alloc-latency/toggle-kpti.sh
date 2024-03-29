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
	if [ $users -gt 1 ]; then
		die "[E] Cannot toggle KPTI: there are $users logged in; please coordinate on machine use."
	fi

	if ! test -f "$GRUB_FILE"; then
		die "[E] This machine does not seem to use GRUB, but this script only supports GRUB."
	fi
}

function prompt {
	while true; do
		read -p "${1}Proceed? [y/n] " yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) exit 1;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

function off {
	checks

	if grep -q "pti=off" $GRUB_FILE; then
		die "[E] KPTI is already disabled."
	fi

	if grep -q "nopti" $GRUB_FILE; then
		die "[E] KPTI is already disabled."
	fi

	prompt "This script is going disable KPTI on this machine, which requires a reboot. "

	echo -n "[I] Command line before changes: "
	echo $(cat $GRUB_FILE | grep "GRUB_CMDLINE_LINUX=" | sed "s/.*GRUB_CMDLINE_LINUX=//g")

	cp $GRUB_FILE /tmp/.tmp_grub

	echo -n "[I] Editing kernel command line..."
	sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"pti=off /g" /tmp/.tmp_grub

	if grep -q "pti=off" /tmp/.tmp_grub; then
		echo " done."
	else
		echo ""
		die "[E] Failed to edit kernel command line."
	fi

	echo -n "[I] Command line after changes: "
	echo $(cat /tmp/.tmp_grub | grep "GRUB_CMDLINE_LINUX=" | sed "s/.*GRUB_CMDLINE_LINUX=//g")

	prompt ""

	cp /tmp/.tmp_grub $GRUB_FILE

	echo "[I] Reconfiguring GRUB..."
	update-grub

	echo "[W] Rebooting in 3s..."
	sleep 3
	reboot
}

function on {
	checks

	if grep -q "pti=on" $GRUB_FILE; then
		die "[E] KPTI is already enabled."
	fi

	if ! grep -q "nopti" $GRUB_FILE; then
		if ! grep -q "pti=off" $GRUB_FILE; then
			die "[E] KPTI is already enabled."
		fi
	fi

	prompt "This script is going enable KPTI on this machine, which requires a reboot. "

	echo -n "[I] Command line before changes: "
	echo $(cat $GRUB_FILE | grep "GRUB_CMDLINE_LINUX=" | sed "s/.*GRUB_CMDLINE_LINUX=//g")

	cp $GRUB_FILE /tmp/.tmp_grub

	echo "[I] Editing kernel command line..."
	sed -i "s/pti=off//g" /tmp/.tmp_grub
	sed -i "s/nopti//g" /tmp/.tmp_grub

	echo -n "[I] Command line after changes: "
	echo $(cat /tmp/.tmp_grub | grep "GRUB_CMDLINE_LINUX=" | sed "s/.*GRUB_CMDLINE_LINUX=//g")

	prompt ""

	cp /tmp/.tmp_grub $GRUB_FILE

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
