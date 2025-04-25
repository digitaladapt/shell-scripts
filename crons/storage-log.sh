#!/usr/bin/env bash

locations="$@"

# load in defaults from config
scriptRoot="$(dirname "$0")/.."
configFile="$scriptRoot/config.sh"
if [[ -f "$configFile" ]]; then
    source "$configFile"

    if [[ -z "$locations" ]]; then
        locations=${STORAGE_MONITOR[@]}
    fi
fi

"$scriptRoot/df-custom.sh" $locations | "$scriptRoot/discord.sh" -c "blue" -t "Storage Status"

