#!/bin/bash
set -xe
DIR=$1
if [[ "${DIR}" == "" ]]; then
  echo "Usage: $0 DIR"
  exit 1
fi

# Setting this manually since we are not running via ukbench
WAYFINDER_CORE_ID0=10
WAYFINDER_CORE_ID1=12
WAYFINDER_CORE_ID2=14

echo "performance" > /sys/devices/system/cpu/cpu${WAYFINDER_CORE_ID0}/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu${WAYFINDER_CORE_ID1}/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu${WAYFINDER_CORE_ID2}/cpufreq/scaling_governor

QEMU_GUEST=${QEMU_GUEST:-./support/qemu-guest}
BRIDGE=asplosae$WAYFINDER_CORE_ID0 # create a unique bridge
BRIDGE_IP="172.${WAYFINDER_CORE_ID0}.${WAYFINDER_CORE_ID1}.1"
UNIKERNEL_INITRD=${UNIKERNEL_INITRD:-./redis.cpio}
UNIKERNEL_IP="172.${WAYFINDER_CORE_ID0}.${WAYFINDER_CORE_ID1}.2"
NUM_PARALLEL_CONNS=${NUM_PARALLEL_CONNS:-30}
ITERATIONS=${ITERATIONS:-5}
RESULTS=${RESULTS:-./results.txt}
CHUNKS=${CHUNKS:-5 50 500}
BOOT_WARMUP_SLEEP=${BOOT_WARMUP_SLEEP:-4}
NUM_REQUESTS=${NUM_REQUESTS:-100000}

if [[ ! -f ${RESULTS} ]]; then
  echo "TASKID,CHUNK,ITERATION,METHOD,VALUE" > ${RESULTS}
fi

if [[ ! -f $UNIKERNEL_INITRD ]]; then
  echo "Missing initram image!"
  exit 1
fi

function cleanup {
  echo "Cleaning up..."
  pkill qemu-system-x86_64 || true
  docker stop asplos22-ae-fig-06-redis
}

function DOCKER_EXEC {
  docker exec -it asplos22-ae-fig-06-redis "$@"
}

echo "Starting intermediate docker container"
docker run -d -it --rm --name asplos22-ae-fig-06-redis \
  -v $(pwd):$(pwd) \
  -v ${DIR}:${DIR} \
  -w $(pwd) \
  --security-opt seccomp:unconfined \
  --privileged \
  ghcr.io/project-flexos/flexos-ae-base:latest bash -c "while true; do sleep 1; done"

echo "Waiting for docker image to start..."
sleep 5


trap "cleanup" EXIT

echo "Creating bridge..."
DOCKER_EXEC brctl addbr ${BRIDGE} || true
DOCKER_EXEC ifconfig ${BRIDGE} down
DOCKER_EXEC ifconfig ${BRIDGE} ${BRIDGE_IP}
DOCKER_EXEC ifconfig ${BRIDGE} up

for D in ${DIR}/*; do
  if [[ ! -d ${D} ]]; then continue; fi

  TASKID=$(basename ${D})
  UNIKERNEL_IMAGE=${D}/usr/src/unikraft/apps/redis/build/redis_kvm-x86_64

  if [[ ! -f ${UNIKERNEL_IMAGE} ]]; then
    continue
  fi

  for CHUNK in ${CHUNKS}; do
    for ((I=1; I<=${ITERATIONS};I++)) do
      echo "Starting unikernel..."

      DOCKER_EXEC taskset -c ${WAYFINDER_CORE_ID0} \
        ${QEMU_GUEST} \
          -k ${UNIKERNEL_IMAGE} \
          -x \
          -m 1024 \
          -i ${UNIKERNEL_INITRD} \
          -b ${BRIDGE} \
          -p ${WAYFINDER_CORE_ID1} \
          -a "netdev.ipv4_addr=${UNIKERNEL_IP} netdev.ipv4_gw_addr=${BRIDGE_IP} netdev.ipv4_subnet_mask=255.255.255.0 vfs.rootdev=ramfs -- /redis.conf"

      echo "Sleeping ${BOOT_WARMUP_SLEEP}..."
      sleep ${BOOT_WARMUP_SLEEP}

      echo "Starting experiment..."
      DOCKER_EXEC \
          taskset -c ${WAYFINDER_CORE_ID2} \
          redis-benchmark \
            -h ${UNIKERNEL_IP} -p 6379 \
            -n ${NUM_REQUESTS} \
            --csv \
            -q \
            -c 30 \
            -k 1 \
            -P 16 \
            -t get,set \
            -d ${I} | \
              awk -v prefix="${TASKID},${CHUNK},${I}" '{ print prefix "," $0 }' >> ${RESULTS}
      sed -i 's/"//g' sed -i 's/"//g'
      DOCKER_EXEC pkill qemu-system-x86
    done
  done
done
