#!/usr/bin/env bash

locations="$@"
hostname=$(hostname)

# load in defaults from config
scriptRoot="$(dirname "$0")/.."
configFile="${scriptRoot}/config.sh"
if [[ -f "${configFile}" ]]; then
    source "${configFile}"

    if [[ -z "{$locations}" ]]; then
        locations=${STORAGE_MONITOR[@]}
    fi
fi

"${scriptRoot}/df.sh" $locations | ntfy pub -T blue_square -t "Storage status on $hostname" storage

