#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/../config.sh"

thermal=`${LOCATION}/../thermal.sh ${THERMAL_ALERT}`
alert=$?

if [[ "0" != "${alert}" ]]; then
    echo "${thermal}, above threshold ${THERMAL_ALERT} C"
    ${LOCATION}/../discord.sh thermal "${thermal}, above threshold ${THERMAL_ALERT} C"
    touch "${LOCATION}/thermal.status"
elif [[ -f "${LOCATION}/thermal.status" ]]; then
    rm "${LOCATION}/thermal.status"
    echo "${thermal}, previously above threshold ${THERMAL_ALERT} C"
    ${LOCATION}/../discord.sh thermal "${thermal}, previously above threshold ${THERMAL_ALERT} C"
else
    echo "${thermal}, below threshold ${THERMAL_ALERT} C"
fi

