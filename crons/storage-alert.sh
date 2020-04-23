#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/../config.sh"

for index in "${!STORAGE_ALERT[@]}"; do
    storage=`${LOCATION}/../storage.sh $index ${STORAGE_ALERT[$index]}`
    alert=$?

    if [[ "0" != "${alert}" ]]; then
        echo "${storage} is below threshold ${STORAGE_ALERT[$index]}G"
        ${LOCATION}/../discord.sh storage "${storage} is below threshold ${STORAGE_ALERT[$index]}G"
    else
        echo "${storage} is above threshold ${STORAGE_ALERT[$index]}G"
    fi
done

