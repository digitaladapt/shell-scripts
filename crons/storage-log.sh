#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/../config.sh"

storage=`${LOCATION}/../df-custom.sh ${STORAGE_MONITOR[@]}`

echo "${storage}"
${LOCATION}/../discord.sh block "${storage}"

