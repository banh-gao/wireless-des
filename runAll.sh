#!/bin/sh

for i in $(seq 0 $2); do
    echo "Running simulation $i of $2 ..."
    ./main.py -c $1 -r $i
    echo ""
done
