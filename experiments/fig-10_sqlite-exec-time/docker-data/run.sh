#!/bin/bash

#set -x

# Run SQLite benchmark for Linux (userland process), Unikraft 0.5 (linuxu and
# kvm), FlexOS (kvm), CubicleOS (linuxu).

apt install -y bc

mkdir -p /out/results
final=/out/results/iperf.dat
rm $final && touch $final

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
  echo "$1 $2 $avg" >> $final
  total=0
  runs=0
}

benchmark_process() {
  header $1 "process"
  for j in $( seq 0 $REPS ); do
    script .out -c "./process-start.sh"
    parse_output $j
  done
  output_avg $2 $3
}

benchmark_linuxu() {
  header $1 "linuxu"
  for j in $( seq 0 $REPS ); do
    script .out -c "./linuxu-start.sh"
    parse_output $j
  done
  output_avg $2 $3
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
  output_avg $2 $3
}

# ---------
# BENCHMARK
# ---------

# Unikraft 0.5

pushd unikraft-mainline/apps
pushd app-sqlite-kvm
benchmark_kvm "unikraft-mainline" 1 "\"NONE\""
popd
pushd app-sqlite-linuxu
benchmark_linuxu "unikraft-mainline" 2 "\"NONE\""
popd
popd

# FlexOS NONE

pushd flexos/apps/sqlite-fcalls
benchmark_kvm "flexos-nompk" 4 "\"NONE\""
popd

# FlexOS MPK 3 COMP

pushd flexos/apps/sqlite-mpk3
benchmark_kvm "flexos-mpk3" 5 "\"MPK3\""
popd

# FlexOS EPT 2 COMP

pushd flexos/apps/sqlite-ept2
benchmark_kvm "flexos-ept2" 6 "\"EPT2\""
popd

# Linux userland

pushd linux-userland
benchmark_process "linux-userland" 8 "\"PT2\""
popd

# SeL4

# TODO

# CubicleOS NO MPK

pushd cubicleos/CubicleOS/CubicleOS/app-sqlite
benchmark_linuxu "cubicleos-nompk" 12 "\"NONE\""
popd

# CubicleOS MPK 3 COMP

pushd cubicleos/CubicleOS/CubicleOS/kernel
# pre-configured for the 3-compartment scenario
benchmark_linuxu "cubicleos-mpk3" 13 "\"MPK3\""
popd

cat $tmp
