#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/../thermal.sh"
${LOCATION}/../discord.sh thermal `${LOCATION}/../thermal.sh`

