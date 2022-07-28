#!/bin/bash

LOCATION=`dirname "$0"`

missed_blocks=`curl -s 'https://api-evmos.cosmostation.io/v1/staking/validator/uptime/evmosvaloper187860d5xukeksge9jz3wwff7h68asdafxdxh4r' | jq '.uptime | length'`

if [ "$missed_blocks" -gt 0 ]; then
    `${LOCATION}/discord.sh general "EVMOS is missing ${missed_blocks} blocks out of the last 100."`
fi

echo -n "${missed_blocks},"

if [ -z `date | grep ':00:'` ]; then
    echo ""
    date
fi

