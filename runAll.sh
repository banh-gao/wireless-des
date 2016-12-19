#!/bin/bash

PIDs=()

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
    echo "usage: $0 confSection maxSimulation"
    exit 0
fi

max=$2

for i in $(seq 0 $max); do
    echo "Starting simulation #$i ..."
    ./main.py -c config.json -s $1 -r $i 1> "sim_$i.log" &
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
R --no-save < compress.R 1> /dev/null

echo "Cleaning up temp files ..."
rm output_*.csv

echo "Results saved in alld.Rdata"
