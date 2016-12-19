#!/bin/bash

PIDs=()

# Setup proper cleanup
cleanup() {
    for pid in "${PIDs[@]}"; do
        kill $pid
    done
    echo""
    echo "Simulations abnormally halted!"
    exit 1
}

trap cleanup HUP INT QUIT KILL PIPE TERM

if [ $# -ne 2 ]; then
    echo "usage: $0 confSection maxSimulation"
    exit 1
fi

max=$2

echo "Running $((max + 1)) simulations (from #0 to #$max) ..."
for i in $(seq 0 $max); do
    ./main.py -c config.json -s $1 -r $i 1> "sim_$i.log" &
    PIDs[$i]=$!
done

i=0
for pid in "${PIDs[@]}"; do
    wait $pid
    remaining=$((max - $i))
    if [ $remaining -ne 0 ]; then
        echo "Simulation #$i ended. $remaining simulations still running ..."
    else
        echo "Simulation #$i ended."
    fi
    i=$((i+1))
done

echo "All $((max + 1)) simulations successfully ended."
