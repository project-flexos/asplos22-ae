#!/bin/bash

CPU_ISOLED1=$1
CPU_ISOLED2=$2

# verbose output
set -x

function cleanup {
	# kill all children (evil)
	pkill -P $$
}

trap "cleanup" EXIT

taskset -c $CPU_ISOLED1 \
	/root/unikraft-mainline/apps/app-sqlite-linuxu/build/app-sqlite_linuxu-x86_64 \
	-mmap 0 database.db
