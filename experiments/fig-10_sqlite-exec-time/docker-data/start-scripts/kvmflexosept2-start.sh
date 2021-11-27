#!/bin/bash

CPU_ISOLED1=$1
CPU_ISOLED2=$2

# -----

# EDIT ME if you run me elsewhere

QEMU_BIN="/root/qemu-system-ept"

# -----

# you should not need to edit these

MEM=2G

run() {
  # run compartment 1 (with delay)
  sleep 3 && taskset -c $CPU_ISOLED1 $QEMU_BIN -enable-kvm -daemonize -display none \
    -device myshmem,file=/data_shared,size=0x2000,paddr=0x105000 \
    -device myshmem,file=/rpc_page,size=0x100000,paddr=0x800000000 \
    -device myshmem,file=/heap,size=0x8000000,paddr=0x4000000000 \
    -initrd /root/flexos/apps/sqlite-fcalls/sqlite.cpio -kernel ${1}.comp1 \
    -m $MEM -L /root/pc-bios &

  # run compartment 0
  taskset -c $CPU_ISOLED2 $QEMU_BIN -enable-kvm -nographic \
    -device myshmem,file=/data_shared,size=0x2000,paddr=0x105000 \
    -device myshmem,file=/rpc_page,size=0x100000,paddr=0x800000000 \
    -device myshmem,file=/heap,size=0x8000000,paddr=0x4000000000 \
    -kernel ${1}.comp0 -m $MEM -append "database.db" -L /root/pc-bios

  pkill -9 qemu-system-x86
  pkill -9 qemu-system-ept
}

run /root/flexos/apps/sqlite-ept2/build/sqlite_kvm-x86_64
