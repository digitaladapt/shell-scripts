#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/config.sh"

HOOK_ARG="$1"
MESSAGE=`echo "${@:2}" | jq -aRs .`
HOOK="general"
HOOK_URL=$DISCORD_GENERAL_HOOK

case $HOOK_ARG in
    thermal)
        HOOK="thermal"
        HOOK_URL=$DISCORD_THERMAL_HOOK
        ;;
    storage)
        HOOK="storage"
        HOOK_URL=$DISCORD_STORAGE_HOOK
        ;;
esac

curl -s -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_SERVER_NAME}\", \"content\": ${MESSAGE}}" $HOOK_URL | jq -r '.id'

