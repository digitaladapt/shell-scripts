#!/bin/bash

device="$1"

usage=`df --output=pcent $device | tail -n 1 | grep -oE '[0-9]+'`
open=`echo "100 - $usage" | bc`
avail=`df --output=avail -h $device | tail -n 1`

echo "Available: $avail ($open%) $device"

if (( "$#" > "1" )); then
    number=`df --output=avail $device | tail -n 1`
    exit `echo "$number <= ($2 * 1024 * 1024)" | bc`
fi

