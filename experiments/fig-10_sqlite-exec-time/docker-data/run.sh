#!/bin/bash

#set -x

# Run SQLite benchmark for Linux (userland process), Unikraft 0.5 (linuxu and
# kvm), FlexOS (kvm), CubicleOS (linuxu).

apt install -y bc

tmp=$(mktemp)
touch $tmp

# ---------
# CONSTANTS
# ---------

# number of reps in this benchmark
REPS=10

# -------
# HELPERS
# -------

total=0
runs=0

header() {
  head="${1} ${2}"
  printf "%0.s-" $(seq 1 ${#head}) >> $tmp
  echo "" >> $tmp
  echo $head >> $tmp
  echo -e "run\ttime (s)" >> $tmp
}

parse_output() {
  # remove everything before TOTAL in case one of the images uses uk_pr_* functions
  res=`cat .out | sed "s/.*TOTAL/TOTAL/g" | awk -e '$0 ~ /TOTAL.../ {print $2}' | sed 's/[a-zA-Z]//g' | tr -d '\r'`
  if [ -z "$res" ]
  then
    echo -e "${1}\tERROR" >> $tmp
  else
    echo -e "${1}\t$res" >> $tmp
    runs=$((runs+1))
    total=$(echo "$total + $res" | bc -l)
  fi
}

output_avg() {
  avg=$(echo "scale=3; $total / $runs" | bc -l )
  echo -e "AVERAGE = ${avg}s (${total}/${runs})" >> $tmp
  total=0
  runs=0
}

benchmark_process() {
  header $1 "process"
  for j in $( seq 0 $REPS ); do
    script .out -c "./process-start.sh"
    parse_output $j
  done
  output_avg
}

benchmark_linuxu() {
  header $1 "linuxu"
  for j in $( seq 0 $REPS ); do
    script .out -c "./linuxu-start.sh"
    parse_output $j
  done
  output_avg
}

benchmark_kvm() {
  header $1 "KVM"
  for j in $( seq 0 $REPS ); do
    {
      sleep 3
      killall -9 qemu-system-x86
    } &
    script .out -c "./kvm-start.sh"
    wait
    parse_output $j
  done
  output_avg
}

# ---------
# BENCHMARK
# ---------

# Linux userland

pushd linux-userland
benchmark_process "linux-userland"
popd

# Unikraft 0.5

pushd unikraft-mainline/apps
pushd app-sqlite-kvm
benchmark_kvm "unikraft-mainline"
popd
pushd app-sqlite-linuxu
benchmark_linuxu "unikraft-mainline"
popd
popd

# FlexOS NONE

pushd flexos/apps/sqlite-fcalls
benchmark_kvm "flexos-nompk"
popd

# FlexOS MPK 3 COMP

pushd flexos/apps/sqlite-mpk3
benchmark_kvm "flexos-mpk3"
popd

# FlexOS EPT 2 COMP

pushd flexos/apps/sqlite-ept2
benchmark_kvm "flexos-ept2"
popd

# CubicleOS NO MPK

pushd cubicleos/CubicleOS/CubicleOS/app-sqlite
benchmark_linuxu "cubicleos-nompk"
popd

# CubicleOS MPK 3 COMP

pushd cubicleos/CubicleOS/CubicleOS/kernel
# pre-configured for the 3-compartment scenario
benchmark_linuxu "cubicleos-mpk3"
popd

cat $tmp
