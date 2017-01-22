#!/bin/bash

set -e

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -ne 3 ]; then
    echo "usage: $0 confFile simulation outDir"
    exit 0
fi

# Setup proper cleanup
cleanup() {
    echo "Simulation abnormally halted!"
    echo "See simulation data in $RES_DIR"
    exit 1
}

trap cleanup HUP INT QUIT KILL PIPE TERM
DATAFILE=$($SRC_DIR/main.py -c $1 -r $2 -o $3)

Rscript $SRC_DIR/process.R $DATAFILE $3
