#!/bin/bash

# Run microbenchmark and process data for FlexOS.

mkdir -p /out/results
final_latcy=/out/results/latency-flexos.dat
final_alloc=/out/results/dss.dat
rm $final_latcy && touch $final_latcy
rm $final_alloc && touch $final_alloc

# -------
# RESULTS
# -------

function_cost=0
mpklight_cost=0
mpkdss_cost=0
ept_cost=0

dss1=0
dss2=0
dss3=0

heap1=0
heap2=0
heap3=0

# -------
# HELPERS
# -------

parse_output() {
  # TODO
}

benchmark_kvm() {
  header $1 "KVM"
  {
    sleep 3
    killall -9 qemu-system-x86
  } &
  script .out -c "./kvm-start.sh"
  wait
  parse_output $j
}

# ---------
# BENCHMARK
# ---------

# FlexOS MPK 2 COMP noisolstack

pushd flexos/apps/flexos-microbenchmarks-mpk2-noisolstack
benchmark_kvm "flexos-mpk2-noisolstack"
popd

# FlexOS MPK 2 COMP isolstack

pushd flexos/apps/flexos-microbenchmarks-mpk2-isolstack
benchmark_kvm "flexos-mpk2-isolstack"
popd

# FlexOS EPT 2 COMP

pushd flexos/apps/flexos-microbenchmarks-ept2
benchmark_kvm "flexos-ept2"
popd

# some of the KVM experiments mess the terminal up
reset

# -------------
# FORMAT OUTPUT
# -------------

# TODO
