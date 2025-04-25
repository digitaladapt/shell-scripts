#!/usr/bin/env bash

alertLevel="$1"

# load in defaults from config
scriptRoot=$(dirname "$0")
configFile="$scriptRoot/config.sh"
if [[ -f "$configFile" ]]; then
    source "$configFile"

    if [[ -z "$alertLevel" ]]; then
        alertLevel="$THERMAL_ALERT"
    fi
fi

# loop over all thermal zones
while read -r mcFile; do
    # each zone has two files we use:
    # "./temp" <int> zone temp (milli-celsius)
    # "./type" <string> zone title
    titleFile=$(echo "$mcFile" | sed 's/temp/type/')
    title=$( < "$titleFile")
    mc=$( < "$mcFile")

    # calculate Celcius and Fahrenheit
    c=$(echo "scale=1 ; $mc / 1000.0" | bc -l)
    f=$(echo "scale=1 ; $c * 9 / 5 + 32" | bc -l)
    hot=$(echo "$c >= $alertLevel" | bc -l)

    echo "$title: $c C ($f F)"

    # if we have reached our alert threshold, mark it as active
    if [[ -n "$alertLevel" ]] && [[ "$hot" -gt 0 ]]; then
        alertActive=1
    fi

done <<< $(find /sys/class/thermal/thermal*/ -name 'temp')

# we exit with a status code of 1 to indicate alert level has been reached
if [[ "$alertActive" -eq 1 ]]; then
    exit 1
fi

