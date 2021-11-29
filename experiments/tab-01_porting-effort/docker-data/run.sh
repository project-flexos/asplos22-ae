#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

SECONDS=0

# Count SLOC/share variable changes in FlexOS ports

FLEXOSROOT=/root/flexos/

mkdir -p /out/results
tmp=/out/results/porting.dat
rm $tmp && touch $tmp

# -------
# HELPERS
# -------

function no_shared {
}

function no_plusminus {
}

# ------------
# MEASUREMENTS
# ------------

# lwip
pushd ${FLEXOSROOT}/libs/lwip
popd

# main tree - scheduler
pushd ${FLEXOSROOT}/unikraft
# TODO
popd

# main tree - fs
pushd ${FLEXOSROOT}/unikraft
# TODO
popd

# main tree - time
pushd ${FLEXOSROOT}/unikraft
# TODO
popd

# Redis
pushd ${FLEXOSROOT}/libs/redis
# TODO
popd

# Nginx
pushd ${FLEXOSROOT}/libs/nginx
# TODO
popd

# SQLite
pushd ${FLEXOSROOT}/libs/sqlite
# TODO
popd

# iPerf (the app contains code as well)
pushd ${FLEXOSROOT}/libs/iperf
# TODO
popd
pushd ${FLEXOSROOT}/apps/iperf
# TODO
popd

# remove the first two empty lines
tail +3 $tmp
cat $tmp

duration=$SECONDS
echo "Runtime: $(($duration / 60)) minutes and $(($duration % 60)) seconds."
