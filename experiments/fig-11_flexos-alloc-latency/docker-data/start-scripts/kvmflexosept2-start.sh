#!/bin/bash

CPU_ISOLED1=$3
CPU_ISOLED2=$4

die() { echo "$*" 1>&2 ; exit 1; }

# -----

# EDIT ME if you run me elsewhere

QEMU_BIN="/root/qemu-system-ept"

# -----

# you should not need to edit these

MEM=2G

run() {
  if [ -z "$CPU_ISOLED1" ]
  then
    die "Usage:\t$0 run <image> <cpu1> <cpu2>\n\t$0 kill"
  fi
  if [ -z "$CPU_ISOLED2" ]
  then
    die "Usage:\t$0 run <image> <cpu1> <cpu2>\n\t$0 kill"
  fi

  TEMP=$(mktemp -d)

  {
    sleep 3
    # run compartment 1
    taskset -c $CPU_ISOLED1 $QEMU_BIN -enable-kvm -daemonize \
      -device myshmem,file=/data_shared,paddr=0x105000,size=0x2000 \
      -device myshmem,file=/rpc_page,paddr=0x800000000,size=0x100000 \
      -device myshmem,file=/heap,paddr=0x4000000000,size=0x8000000 \
      -initrd /root/img.cpio -display none -cpu host \
      -kernel ${1}.comp1 -m $MEM -L /root/pc-bios
  } &

  # run compartment 0
  taskset -c $CPU_ISOLED2 $QEMU_BIN -enable-kvm -nographic \
    -device myshmem,file=/data_shared,size=0x2000,paddr=0x105000 \
    -device myshmem,file=/rpc_page,size=0x100000,paddr=0x800000000 \
    -device myshmem,file=/heap,size=0x8000000,paddr=0x4000000000 \
    -initrd /root/img.cpio -cpu host \
    -kernel ${1}.comp0 -m $MEM -L /root/pc-bios
}

killimg() {
  pkill -9 qemu-system-x86
  pkill -9 qemu-system-ept
}

if [ $# -gt 4 ]; then
  die "Usage:\t$0 run <image> <cpu1> <cpu2>\n\t$0 kill"
elif [ $# -eq 0 ]; then
  die "Usage:\t$0 run <image> <cpu1> <cpu2>\n\t$0 kill"
else
  case "$1" in
    run)
      run $2
      ;;
    kill)
      killimg
      ;;
    *)
      die "'$1': unsupported argument."
      ;;
  esac
fi
