#!/bin/bash

# verbose output
set -x

function cleanup {
	# kill all children (evil)
	pkill qemu-system-x86
	pkill -P $$
}

trap "cleanup" EXIT

/root/qemu-guest \
	-k /root/flexos/apps/sqlite-mpk3/build/sqlite_kvm-x86_64 \
	-m 1000 -a "-mmap 0 database.db" -i /root/flexos/apps/sqlite-mpk3/sqlite.cpio

# stop server
pkill qemu-system-x86
pkill qemu
pkill qemu*

