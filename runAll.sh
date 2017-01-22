#!/bin/bash

set -e

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TMP_DIR=$(mktemp -d /tmp/sim.XXX)
OUT_DIR="$( pwd )"

if [ $# -ne 2 ]; then
    echo "usage: $0 confFile maxSimulation"
    exit 0
fi

# Setup proper cleanup
cleanup() {
    echo "Simulations abnormally halted!"
    echo "See simulations data in $TMP_DIR"
    exit 1
}

trap cleanup HUP INT QUIT KILL PIPE TERM

echo "Running simulations from 0 to $2 ..."
parallel --progress "$SRC_DIR/runSingle.sh $1 {} $TMP_DIR > $TMP_DIR/sim_{}.log 2>&1" ::: $(seq 0 $2)

echo "Interpolating results ..."
Rscript --vanilla $SRC_DIR/interpolate.R $TMP_DIR $OUT_DIR

echo "Results saved in $OUT_DIR/alld.Rdata"
