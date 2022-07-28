#!/bin/bash

LOCATION=`dirname "$0"`

missed_blocks=`curl -s 'https://api-evmos.cosmostation.io/v1/staking/validator/uptime/evmosvaloper187860d5xukeksge9jz3wwff7h68asdafxdxh4r' | jq '.uptime | length'`

if [ "$missed_blocks" -gt 2 ]; then
    `${LOCATION}/discord.sh general "EVMOS is missing ${missed_blocks} blocks out of the last 100."`
fi

echo -n "${missed_blocks},"

if [ `date | grep -c ':00:'` -gt 0 ]; then
    echo ""
    date
fi

