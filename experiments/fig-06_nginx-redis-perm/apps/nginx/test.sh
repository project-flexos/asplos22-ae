#!/bin/bash
set -x

DIR=$1

if [[ "${DIR}" == "" ]]; then
  echo "Usage: $0 DIR"
  exit 1
fi

# Setting this manually since we are not running via wayfinder
WAYFINDER_CORE_ID0=10
WAYFINDER_CORE_ID1=12
WAYFINDER_CORE_ID2=14

echo "performance" > /sys/devices/system/cpu/cpu${WAYFINDER_CORE_ID0}/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu${WAYFINDER_CORE_ID1}/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu${WAYFINDER_CORE_ID2}/cpufreq/scaling_governor

QEMU_GUEST=${QEMU_GUEST:-./qemu-guest}
BRIDGE=asplosae$WAYFINDER_CORE_ID0 # create a unique bridge
BRIDGE_IP="172.${WAYFINDER_CORE_ID0}.${WAYFINDER_CORE_ID1}.1"
UNIKERNEL_INITRD=${UNIKERNEL_INITRD:-./nginx.cpio}
UNIKERNEL_IP="172.${WAYFINDER_CORE_ID0}.${WAYFINDER_CORE_ID1}.2"
NUM_PARALLEL_CONNS=${NUM_PARALLEL_CONNS:-30}
NUM_THREADS=${NUM_THREADS:-14}
ITERATIONS=${ITERATIONS:-5}
DURATION=${DURATION:-10s}
RESULTS=${RESULTS:-./results.txt}
BOOT_WARMUP_SLEEP=${BOOT_WARMUP_SLEEP:-4}
CHUNK=0

if [[ ! -f ${RESULTS} ]]; then
  echo "TASKID,CHUNK,ITERATION,METHOD,VALUE" > ${RESULTS}
fi

if [[ ! -f ${UNIKERNEL_INITRD} ]]; then
  echo "Missing initram image!"
  exit 1
fi

function cleanup {
  echo "Cleaning up..."
  ifconfig ${BRIDGE} down || true
  brctl delbr ${BRIDGE} || true
  pkill qemu-system-x86_64 || true
}

trap "cleanup" EXIT

echo "Creating bridge..."
brctl addbr ${BRIDGE} || true
ifconfig ${BRIDGE} down
ifconfig ${BRIDGE} ${BRIDGE_IP}
ifconfig ${BRIDGE} up

for D in ${DIR}/*; do
  if [[ ! -d ${D} ]]; then continue; fi
 
  TASKID=$(basename ${D})
  UNIKERNEL_IMAGE=${D}/usr/src/unikraft/apps/nginx/build/nginx_kvm-x86_64

  if [[ ! -f ${UNIKERNEL_IMAGE} ]]; then
    continue
  fi

  for ((I=1; I<=${ITERATIONS};I++)) do
    echo "Starting unikernel..."

    echo "${UNIKERNEL_IMAGE}"
    taskset -c ${WAYFINDER_CORE_ID0} \
      ${QEMU_GUEST} \
        -x \
        -k ${UNIKERNEL_IMAGE} \
        -m 1024 \
        -i ${UNIKERNEL_INITRD} \
        -b ${BRIDGE} \
        -p ${WAYFINDER_CORE_ID1} \
        -a "netdev.ipv4_addr=${UNIKERNEL_IP} netdev.ipv4_gw_addr=${BRIDGE_IP} netdev.ipv4_subnet_mask=255.255.255.0 vfs.rootdev=ramfs --"

    echo "Sleeping ${BOOT_WARMUP_SLEEP}..."
    sleep ${BOOT_WARMUP_SLEEP}

    echo "Starting experiment..."
    taskset -c ${WAYFINDER_CORE_ID2} \
      wrk \
        -t ${NUM_THREADS} \
        -c ${NUM_PARALLEL_CONNS} \
        -d ${DURATION} \
        http://${UNIKERNEL_IP} | \
        awk 'BEGIN{a["Requests/sec:"]} ($1 in a) && ($2 ~ /[0-9]/){print $2}' | \
        awk -v prefix="${TASKID},${CHUNK},${I},REQ" '{ print prefix "," $0 }' >> ${RESULTS}

      pkill qemu-system-x86
      pkill qemu
      pkill qemu*
    done
done


