#!/bin/bash

if (( "0" == "$#" )); then
    device="/"

    usage=`df --output=pcent $device | tail -n 1 | grep -oE '[0-9]+'`
    open=`echo "100 - $usage" | bc`
    avail=`df --output=avail -h $device | tail -n 1`

    echo "Available: $avail ($open%) $device"

    exit
fi

for device in "$@"; do

    usage=`df --output=pcent $device | tail -n 1 | grep -oE '[0-9]+'`
    open=`echo "100 - $usage" | bc`
    avail=`df --output=avail -h $device | tail -n 1`

    echo "Available: $avail ($open%) $device"

done

