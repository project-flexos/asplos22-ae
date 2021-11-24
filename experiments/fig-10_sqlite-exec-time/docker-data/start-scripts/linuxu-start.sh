#!/bin/bash

# verbose output
set -x

function cleanup {
	# kill all children (evil)
	pkill -P $$
}

trap "cleanup" EXIT

/root/unikraft-mainline/apps/app-sqlite-linuxu/build/app-sqlite_linuxu-x86_64 \
	-mmap 0 database.db
