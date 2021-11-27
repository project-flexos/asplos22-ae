#!/bin/bash

CPU_ISOLED1=$1
CPU_ISOLED2=$2

# verbose output
set -x

function cleanup {
	# kill all children (evil)
	pkill qemu-system-x86
	pkill -P $$
}

trap "cleanup" EXIT

taskset -c $CPU_ISOLED1 /root/qemu-guest -p $CPU_ISOLED2 \
	-k /root/flexos/apps/sqlite-fcalls/build/sqlite_kvm-x86_64 \
	-m 1000 -a "-mmap 0 database.db" -i /root/flexos/apps/sqlite-fcalls/sqlite.cpio

# stop server
pkill qemu-system-x86
pkill qemu
pkill qemu*

