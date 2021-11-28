#!/bin/bash

CPU_ISOLED1=$3
CPU_ISOLED2=$4
CPU_NOISOLED1=$5
CPU_NOISOLED2=$6
CPU_NOISOLED3=$7
CPU_NOISOLED4=$8

# -----

# EDIT ME if you run me elsewhere

QEMU_BIN="/root/qemu-system-ept"

# -----

# you should not need to edit these

MEM=2G

NETIF=uk0

BASEIP="172.130.0"
GATEWAY="172.130.0.1"

# start a dnsmasq server and echo its PID
function run_dhcp {
    pkill -9 dnsmasq
    dnsmasq -d \
        --log-queries \
        --bind-dynamic \
        --interface=$1 \
        --listen-addr=${2}.1 \
        --dhcp-range=${2}.2,${2}.254,255.255.255.0,12h &> $(pwd)/dnsmasq.log &
    echo $!
}

run() {
  TEMP=$(mktemp -d)

  echo "creating bridge"
  brctl addbr $NETIF || true
  ifconfig $NETIF $GATEWAY
  dnsmasq_pid=$(run_dhcp $NETIF $BASEIP)

  # scripts that handle tap creation
  cat > ${TEMP}/ifup.sh <<EOF
#!/bin/sh
dev=\$1
ifconfig \$1 0.0.0.0 promisc up
brctl addif ${NETIF} \${dev}
EOF

  cat > ${TEMP}/ifdown.sh <<EOF
#!/bin/sh
dev=\$1
brctl delif ${NETIF} \${dev}
ifconfig \$1 down
EOF

  chmod +x ${TEMP}/ifup.sh
  chmod +x ${TEMP}/ifdown.sh

  # run compartment 0
  taskset -c $CPU_NOISOLED1,$CPU_NOISOLED2 $QEMU_BIN -enable-kvm -daemonize -display none \
    -device myshmem,file=/data_shared,size=0x3000,paddr=0x105000 \
    -device myshmem,file=/rpc_page,size=0x100000,paddr=0x800000000 \
    -device myshmem,file=/heap,size=0x8000000,paddr=0x4000000000 \
    -kernel ${1}.comp0 -m $MEM \
    -netdev tap,id=hnet0,vhost=off,script=${TEMP}/ifup.sh,downscript=${TEMP}/ifdown.sh \
    -device virtio-net-pci,netdev=hnet0,id=net0 -L /root/pc-bios

  # let it boot
  sleep 2

  # run compartment 1
  taskset -c $CPU_NOISOLED3,$CPU_NOISOLED4 $QEMU_BIN -enable-kvm -daemonize -display none \
    -device myshmem,file=/data_shared,paddr=0x105000,size=0x3000 \
    -device myshmem,file=/rpc_page,paddr=0x800000000,size=0x100000 \
    -device myshmem,file=/heap,paddr=0x4000000000,size=0x8000000 \
    -kernel ${1}.comp1 -m $MEM -L /root/pc-bios

  # let it boot
  sleep 2
}

killimg() {
  pkill -9 qemu-system-x86
  pkill -9 qemu-system-ept
  pkill -9 dnsmasq
  ifconfig $NETIF down
  brctl delbr $NETIF
}

die() { echo "$*" 1>&2 ; exit 1; }

if [ $# -gt 8 ]; then
  die "Usage:\t$0 run <image>\n\t$0 kill"
elif [ $# -eq 0 ]; then
  die "Usage:\t$0 run <image>\n\t$0 kill"
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
