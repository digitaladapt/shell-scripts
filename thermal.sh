#!/bin/bash

# this is currently specific to raspberry-pi
# since that is the only kind of physical server I have
# TODO make this work with all temp in class/thermal
name=$(</sys/class/thermal/thermal_zone0/type)
mc=$(</sys/class/thermal/thermal_zone0/temp)

c=`echo "scale=1 ; $mc / 1000.0" | bc -l`
f=`echo "scale=1 ; $c * 9 / 5 + 32" | bc -l`

echo "${name}: ${c} C ($f F)"

if (( "$#" > "0" )); then
    exit `echo "$c >= $1" | bc`
fi

