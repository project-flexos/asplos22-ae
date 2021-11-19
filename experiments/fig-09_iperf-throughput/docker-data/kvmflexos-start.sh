#!/bin/bash

NETIF=uk0
IP="172.130.0.2"

function run {
	echo "creating bridge"
	brctl addbr $NETIF || true
	ifconfig $NETIF 172.130.0.1
	/root/qemu-guest -k $1 -x \
		-m 1024 -b ${NETIF} -i /root/flexos/apps/iperf-fcalls/img.cpio \
		-a "netdev.ipv4_addr=${IP} netdev.ipv4_gw_addr=172.130.0.254 netdev.ipv4_subnet_mask=255.255.255.0 --"
}

function killimg {
	ifconfig $NETIF down
	brctl delbr $NETIF
	killall -9 qemu-system-x86 qemu-guest $0
}

die() { echo "$*" 1>&2 ; exit 1; }

if [ $# -gt 2 ]; then
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
