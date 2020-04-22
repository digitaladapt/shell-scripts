#!/bin/bash

name=$(</sys/class/thermal/thermal_zone0/type)
temp=$(</sys/class/thermal/thermal_zone0/temp)
temp="$((temp/1000)).$((temp/100%10))"
echo "${name}: ${temp} C"

if (( "$#" > "0" )); then
    exit `echo "$temp >= $1" | bc`
fi

