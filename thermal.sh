#!/bin/bash

name=$(</sys/class/thermal/thermal_zone0/type)
temp=$(</sys/class/thermal/thermal_zone0/temp)
echo "${name}: $((temp/1000)).$((temp%1000)) C"

