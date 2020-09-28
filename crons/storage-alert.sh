#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/../config.sh"

COUNT=1
for index in "${!STORAGE_ALERT[@]}"; do
    storage=`${LOCATION}/../storage.sh $index ${STORAGE_ALERT[$index]}`
    alert=$?

    if [[ "0" != "${alert}" ]]; then
        echo "${storage} is below threshold ${STORAGE_ALERT[$index]}G"
        ${LOCATION}/../discord-if-distinct.sh storage "storage-${COUNT}" "${storage} is below threshold ${STORAGE_ALERT[$index]}G"
    else
        echo "${storage} is above threshold ${STORAGE_ALERT[$index]}G"

        ${LOCATION}/../discord-if-distinct.sh storage "storage-${COUNT}" "${storage} is above threshold ${STORAGE_ALERT[$index]}G"
    fi

    let "COUNT++"
done

