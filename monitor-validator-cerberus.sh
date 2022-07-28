#!/bin/bash

LOCATION=`dirname "$0"`

missed_blocks=`curl -s 'https://api-cerberus.cosmostation.io/v1/staking/validator/uptime/cerberusvaloper1krkmg6f0sjwalkx3nq39yt0upxgys7alcjytq4' | jq '.uptime | length'`

if [ "$missed_blocks" -gt 0 ]; then
    ${LOCATION}/discord.sh general "Cerberus is missing ${missed_blocks} blocks out of the last 100."
fi

