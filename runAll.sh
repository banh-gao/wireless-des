#!/bin/bash

RES_DIR=/tmp
OUT_DIR="$( pwd )"

PIDs=()
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Setup proper cleanup
cleanup() {
    for pid in "${PIDs[@]}"; do
        kill $pid 2> /dev/null
    done
    echo "Simulations abnormally halted!"
    exit 1
}

trap cleanup HUP INT QUIT KILL PIPE TERM

if [ $# -ne 2 ]; then
    echo "usage: $0 confFile maxSimulation"
    exit 0
fi

max=$2

for i in $(seq 0 $max); do
    echo "Starting simulation #$i ..."
    $SRC_DIR/main.py -c $1 -r $i 1> "$RES_DIR/sim_$i.log" &
    PIDs[$i]=$!
done

i=0
for pid in "${PIDs[@]}"; do
    wait $pid

    # Halt all if simulation failed
    if [ $? -ne 0 ]; then
        echo "SIMULATION FAILURE DETECTED!"
        cleanup
        exit 1
    fi

    echo "Simulation $((i + 1)) of $((max + 1)) ended"
    i=$((i + 1))
done

echo "Compressing results ..."
Rscript --vanilla $SRC_DIR/compress.R $RES_DIR $OUT_DIR 1> /dev/null
echo "Cleaning up temp files ..."
rm $RES_DIR/output_*.csv

echo "Results saved in $OUT_DIR/alld.Rdata"
