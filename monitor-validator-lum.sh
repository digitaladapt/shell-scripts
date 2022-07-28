#!/bin/bash

LOCATION=`dirname "$0"`

missed_blocks=`curl -s 'https://api-lum.cosmostation.io/v1/staking/validator/uptime/lumvaloper1krkmg6f0sjwalkx3nq39yt0upxgys7alme6lps' | jq '.uptime | length'`

if [ "$missed_blocks" -gt 0 ]; then
    `${LOCATION}/discord.sh general "Lum Network is missing ${missed_blocks} blocks out of the last 100."`
fi

echo -n "${missed_blocks},"

if [ `date | grep -c ':00:'` -gt 0 ]; then
    echo ""
    date
fi

