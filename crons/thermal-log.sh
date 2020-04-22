#!/bin/bash

LOCATION=`dirname "$0"`

thermal=`${LOCATION}/../thermal.sh`

echo "${thermal}"
${LOCATION}/../discord.sh thermal "${thermal}"

