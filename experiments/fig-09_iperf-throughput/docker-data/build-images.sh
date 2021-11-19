#!/bin/bash

set_rcvbuf() {
  sed -i "s/#define RECVBUFFERSIZE .*/#define RECVBUFFERSIZE ${1}/g" ./main.c
}

build_img() {
  isept=$( grep -e "CONFIG_LIBFLEXOS_VMEPT=y" .config )
  if [ -n "$isept" ]; then
    # don't use --no-progress here, might cause issues
    make prepare && kraft -v build --fast --compartmentalize
    cp build/iperf_kvm-x86_64.comp0 images/${cur}.img.comp0
    cp build/iperf_kvm-x86_64.comp1 images/${cur}.img.comp1
  else
    make prepare && make -j
    cp build/iperf_kvm-x86_64 images/${cur}.img
  fi
}

mkdir -p ./images

for i in {4..20}; do
  cur=$(echo 2^$i | bc)
  set_rcvbuf $cur 
  build_img
done
