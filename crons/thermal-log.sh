#!/usr/bin/env bash

scriptRoot="$(dirname "$0")/.."
hostname=$(hostname)

# get current status
thermal=$(${scriptRoot}/thermal.sh)

if [[ -n "$thermal" ]]; then
    echo "$thermal" | ntfy pub -T yellow_square -t "Thermal status on $hostname" thermal
fi

