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

function_cost=
mpklight_cost=
mpkdss_cost=
ept_cost=

dss1=
dss2=
dss3=

heap1=
heap2=
heap3=

# -------
# HELPERS
# -------

get_val() {
  echo `cat .out | tr -dc '[:alnum:]\n\r .' \
	  | sed "s/.*$0,/$0,/g" \
	  | awk -e "\$0 ~ /$0,/ {print \$2}" \
	  | sed 's/[a-zA-Z]//g' | tr -d '\r'`
}

set_val() {
  if [ -n "$0" ]; then
    if [ -n "$(eval $1)" ]; then
      echo "ERROR: the same measurement is reevaluated twice. Is this a bug?"
    fi
    eval $1=$0
  fi
}

parse_output() {
  tentative=$(get_val "pku-dss")
  set_val $tentative "mpkdss_cost"

  tentative=$(get_val "pku-heap")
  set_val $tentative "mpklight_cost"

  tentative=$(get_val "ept")
  set_val $tentative "ept_cost"

  tentative=$(get_val "fcall")
  set_val $tentative "function_cost"

  tentative=$(get_val "dss1")
  set_val $tentative "dss1"
  tentative=$(get_val "dss2")
  set_val $tentative "dss2"
  tentative=$(get_val "dss3")
  set_val $tentative "dss3"

  tentative=$(get_val "heap1")
  set_val $tentative "heap1"
  tentative=$(get_val "heap2")
  set_val $tentative "heap2"
  tentative=$(get_val "heap3")
  set_val $tentative "heap3"
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

echo "1   \"function\"   $function_cost"  >> $final_latcy
echo "3   \"MPK-light\"  $mpklight_cost"  >> $final_latcy
echo "4   \"MPK-dss\"    $mpkdss_cost"    >> $final_latcy
echo "5   \"EPT\"        $ept_cost"       >> $final_latcy

echo "Buffers     Heap    DSS     Shared" >> $final_alloc
echo "1           $heap1     $dss1       $function_cost" >> $final_alloc
echo "2           $heap2     $dss2       $function_cost" >> $final_alloc
echo "3           $heap3     $dss3       $function_cost" >> $final_alloc
