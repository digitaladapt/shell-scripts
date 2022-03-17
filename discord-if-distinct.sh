#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/config.sh"

HOOK_ARG="$1"
BOBBY="$2"
MESSAGE=`echo "${@:3}" | jq -aRs .`
HOOK="general"
HOOK_URL=$DISCORD_GENERAL_HOOK

case $HOOK_ARG in
    restake)
        HOOK="restake"
        HOOK_URL=$DISCORD_RESTAKE_HOOK
        ;;
    thermal)
        HOOK="thermal"
        HOOK_URL=$DISCORD_THERMAL_HOOK
        ;;
    storage)
        HOOK="storage"
        HOOK_URL=$DISCORD_STORAGE_HOOK
        ;;
esac

OLD_MSG=""
if [ -f "${LOCATION}/distinct/${BOBBY}.msg" ]; then
    OLD_MSG=`cat "${LOCATION}/distinct/${BOBBY}.msg"`
fi

if [ "${MESSAGE}" != "${OLD_MSG}" ]; then
    echo "${MESSAGE}" > "${LOCATION}/distinct/${BOBBY}.msg"

    curl -s -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_SERVER_NAME}\", \"content\": ${MESSAGE}}" $HOOK_URL | jq -r '.id'
fi
