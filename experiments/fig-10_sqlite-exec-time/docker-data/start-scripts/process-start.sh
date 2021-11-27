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

if mount | grep /tmp | grep tmpfs >/dev/null; then
    ram_disk=/tmp/sqlite_ramdisk
    >&2 echo "/tmp on tmpfs, running experiment from $ram_disk"
    mkdir /tmp/sqlite_ramdisk
else
    ram_disk=/mnt/sqlite_ramdisk
    >&2 echo "We'll mount a RAM disk at $ram_disk"
    mkdir /mnt/sqlite_ramdisk
    mount -t tmpfs none /mnt/sqlite_ramdisk
fi

rm ${ram_disk}/database.db
touch ${ram_disk}/database.db

taskset -c $CPU_ISOLED1 /root/linux-userland/sqlite-benchmark ${ram_disk}/database.db

if [ "$ram_disk" = "/mnt/sqlite_ramdisk" ]; then
    >&2 echo "Unmounting RAM disk"
    umount "$ram_disk"
fi
>&2 echo "Removing $ram_disk"
rmdir "$ram_disk"
