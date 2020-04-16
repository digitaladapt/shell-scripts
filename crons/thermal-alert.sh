#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/../config.sh"

if (( `cat /sys/class/thermal/thermal_zone0/temp` > ( $THERMAL_ALERT * 1000 ) )); then
    echo "thermal above ${THERMAL_ALERT} C"
    source "${LOCATION}/../thermal.sh"
    ${LOCATION}/../discord.sh thermal `${LOCATION}/../thermal.sh`
else
    echo "thermal below ${THERMAL_ALERT} C"
    source "${LOCATION}/../thermal.sh"
fi

