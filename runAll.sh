#!/bin/bash

set -e

RES_DIR=/tmp
OUT_DIR="$( pwd )"

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -ne 2 ]; then
    echo "usage: $0 confFile maxSimulation"
    exit 0
fi


# Setup proper cleanup
cleanup() {
    echo "Simulations abnormally halted!"
    echo "See simulations data in $RES_DIR"
    exit 1
}
trap cleanup HUP INT QUIT KILL PIPE TERM

echo "Running simulations from 0 to $2 ..."
parallel --progress "$SRC_DIR/main.py -c $1 -r {} 1> $RES_DIR/sim_{}.log" ::: $(seq 0 $2)

echo "Compressing results ..."
Rscript --vanilla $SRC_DIR/compress.R $RES_DIR $OUT_DIR
echo "Cleaning up temp files ..."
rm $RES_DIR/output_*.csv

echo "Results saved in $OUT_DIR/alld.Rdata"
