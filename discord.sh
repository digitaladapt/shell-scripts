#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/config.sh"

HOOK_ARG="$1"
MESSAGE=`echo "${@:2}"`

# if message is too long, split it, and after curl, recursively call with remainder
# 2k max, but we must account for escaping text in json, so limit to 90% capacity
EXTRA="${MESSAGE:1800}"

if [ -n "${EXTRA}" ]; then
    MESSAGE="${MESSAGE:0:1800}"
fi

# sed: rewrite json string, because "\u001b[m" needs to "\u001b[0m" instead
MESSAGE=`echo "${MESSAGE}" | jq -aRs . | sed 's/\\\\u001b\[m/\\\\u001b[0m/g'`
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

# if color detected, update message from "<content>" to "```ansi <content>```", so it gets displayed correctly
if [[ "$MESSAGE" == *"\\u001b"* ]]; then
    MESSAGE="\"\`\`\`ansi\n${MESSAGE:1:-1}\n\`\`\`\""
    # just here to resolve formatting issue in vim "`"
fi

curl -s -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_SERVER_NAME}\", \"content\": ${MESSAGE}}" $HOOK_URL | jq -r '.id'

if [ -n "${EXTRA}" ]; then
    "${LOCATION}/discord.sh" "${HOOK}" "${EXTRA}"
fi

