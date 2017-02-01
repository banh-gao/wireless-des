#!/bin/bash

set -e

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TMP_DIR=$(mktemp -d /tmp/sim.XXX)
OUT_DIR="$( pwd )"

if [ $# -ne 2 ]; then
    echo "usage: $0 confFile maxSimulation"
    exit 0
fi

CONF=$1
MAX_SIM=$2
# Setup proper cleanup
cleanup() {
    echo "Simulations abnormally halted!"
    echo "See simulations data in $TMP_DIR"
    exit 1
}

trap cleanup HUP INT QUIT KILL PIPE TERM

echo "Running simulations from 0 to $MAX_SIM ..."
parallel --progress "$SRC_DIR/runSingle.sh $CONF {} $TMP_DIR > $TMP_DIR/sim_{}.log 2>&1" ::: $(seq 0 $MAX_SIM)

echo "Interpolating results ..."
Rscript $SRC_DIR/interpolate.R "$TMP_DIR" "$OUT_DIR"

echo "Plotting results ..."
Rscript $SRC_DIR/plot.R "$OUT_DIR"
