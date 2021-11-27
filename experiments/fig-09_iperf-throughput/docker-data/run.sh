#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

# Run SQLite benchmark for Linux (userland process), Unikraft 0.5 (linuxu and
# kvm), FlexOS (kvm), CubicleOS (linuxu).

CPU_ISOLED1=$1
CPU_ISOLED2=$2
CPU_ISOLED3=$3

die() { echo "$*" 1>&2 ; exit 1; }

if [ -z "$CPU_ISOLED1" ]
then
  die "isolated CPU list not provided (read the main README!)"
fi

if [ -z "$CPU_ISOLED2" ]
then
  die "isolated CPU list not provided (read the main README!)"
fi

if [ -z "$CPU_ISOLED3" ]
then
  die "isolated CPU list not provided (read the main README!)"
fi

apt install -y bc iperf

mkdir -p /out/results
tmp=/out/results/iperf.dat
rm $tmp && touch $tmp

# ---------
# CONSTANTS
# ---------

# number of reps in this benchmark
REPS=5

# -------
# HELPERS
# -------

total=0
runs=0

header() {
  echo "" >> $tmp
  echo "" >> $tmp
  echo "# ${1} ${2}" >> $tmp
  echo "# recvbuf-size  tx" >> $tmp
}

parse_output() {
  res=`cat .out | awk -e '$0 ~ /0.0-/ {print $7}' | tr -d '\r'`
  runs=$((runs+1))
  total=$(echo "$total + $res" | bc -l)
}

output_avg() {
  avg=$(echo "scale=3; $total / $runs" | bc -l )
  echo -e "${1}\t$avg" >> $tmp
  total=0
  runs=0
}

benchmark_kvm() {
  header $1 "KVM"
  t=$((16 * $REPS))
  for i in {4..20}; do
    cur=$(echo 2^$i | bc)
    for j in $( seq 1 $REPS); do
      c=$(($(($i - 4)) * $REPS + $j))
      echo "KVM / $1 run ${c}/${t}"
      isept=$( grep -e "CONFIG_LIBFLEXOS_VMEPT=y" .config )
      ./kvm-start.sh run images/${cur}.img $CPU_ISOLED1 $CPU_ISOLED2
      if [ -n "$isept" ]; then
        script .out -c "taskset -c $CPU_ISOLED3 iperf -c 172.130.0.76 -p 12345 -t 10 --format g"
      else
        script .out -c "taskset -c $CPU_ISOLED3 iperf -c 172.130.0.2  -p 12345 -t 10 --format g"
      fi
      ./kvm-start.sh kill
      parse_output
    done
    output_avg $cur
  done
}

# ---------
# BENCHMARK
# ---------

# Unikraft baseline NONE

pushd unikraft-mainline/apps/app-iperf
benchmark_kvm "unikraft-mainline"
popd

# FlexOS NONE

pushd flexos/apps/iperf-fcalls
benchmark_kvm "flexos-nompk"
popd

# FlexOS MPK 2 COMP isolstack

pushd flexos/apps/iperf-mpk2-isolstack
benchmark_kvm "flexos-mpk2-isolstack"
popd

# FlexOS MPK 2 COMP noisolstack

pushd flexos/apps/iperf-mpk2-noisolstack
benchmark_kvm "flexos-mpk2-noisolstack"
popd

# FlexOS EPT 2 COMP

pushd flexos/apps/iperf-ept2
benchmark_kvm "flexos-ept2"
popd

# remove the first two empty lines
tail +3 $tmp
cat $tmp
