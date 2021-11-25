#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

GRUB_FILE="/etc/default/grub"

set -e

RESULTS=$1
LINUXEXP=$2
CPU=$3

function merge {
	if test -f "${RESULTS}/latency-linux-nokpti.dat"; then
		if test -f "${RESULTS}/latency-linux.dat"; then
			if test -f "${RESULTS}/latency-flexos.dat"; then
				# all benchmarks completed, merge
				cat ${RESULTS}/latency-flexos.dat > ${RESULTS}/latency.dat
				cat ${RESULTS}/latency-linux.dat >> ${RESULTS}/latency.dat
				cat ${RESULTS}/latency-linux-nokpti.dat >> ${RESULTS}/latency.dat
			fi
		fi
	fi
}

if ! grep -Fxq "nopti" $GRUB_FILE; then
	if ! grep -Fxq "pti=off" $GRUB_FILE; then
		# KPTI is enabled
		taskset -c ${3} ${2}/benchmark > .out
		scall=`cat .out | tr -dc '[:alnum:]\n\r .,-' | sed "s/.*scall,/scall,/g" \
			 | grep "^scall," | sed "s/scall,//g" | tr -dc '[:alnum:]'`
		echo "7   \"syscall\"       $scall" > ${1}/latency-linux.dat
		rm .out
		merge
		exit 0
	fi
fi

# KPTI is disabled
taskset -c ${3} ${2}/benchmark > .out
scall=`cat .out | tr -dc '[:alnum:]\n\r .,-' | sed "s/.*scall,/scall,/g" \
	 | grep "^scall," | sed "s/scall,//g" | tr -dc '[:alnum:]'`
echo "8   \"-nokpti\"       $scall" > ${1}/latency-linux-nokpti.dat
rm .out
merge
