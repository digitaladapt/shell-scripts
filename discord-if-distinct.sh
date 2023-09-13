#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/config.sh"

HOOK_ARG="$1"
BOBBY="$2"
# sed removes spaces before each line
MESSAGE=`echo "${@:3}" | sed 's/^ *//'`

# sed removes blank lines from the end of the message
FULL_MESSAGE=`echo "${MESSAGE}" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'`

# if message is too long, split it, and after curl, recursively call with remainder
# 2k max, but we must account for escaping text in json, so limit to 90% capacity
EXTRA="${MESSAGE:1800}"

if [ -n "${EXTRA}" ]; then
    MESSAGE="${MESSAGE:0:1800}"

    # as an added elegance, when spliting into pieces, find the last \n newline,
    # and break there instead, but only if the new smaller chunk is of sufficient size
    chunk1=`echo "$MESSAGE" | head -n -1`
    chunks=`echo "$MESSAGE" | tail -n 1`
    if (( "${#chunk1}" >= 1000 )); then
        MESSAGE="$chunk1"
        EXTRA="${chunks}${EXTRA}"
    fi
fi

# sed: rewrite json string, because "\u001b[m" needs to "\u001b[0m" instead
# linux is fine with the missing zero, but discord needs it
MESSAGE=`echo "${MESSAGE}" | jq -aRs . | sed 's/\\\\u001b\[m/\\\\u001b[0m/g'`
HOOK="general"
HOOK_URL=$DISCORD_GENERAL_HOOK

case $HOOK_ARG in
    block)
        # force block format without color
        if [[ "$MESSAGE" != *"\\u001b"* ]]; then
            MESSAGE="\"\`\`\`${MESSAGE:1:-1}\n\`\`\`\""
            # just here to resolve formatting issue in vim "`"
        fi
        ;;
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

OLD_MSG=""
if [ -f "${LOCATION}/distinct/${BOBBY}.msg" ]; then
    OLD_MSG=`cat "${LOCATION}/distinct/${BOBBY}.msg"`
fi

if [ "${FULL_MESSAGE}" != "${OLD_MSG}" ]; then
    echo "${FULL_MESSAGE}" > "${LOCATION}/distinct/${BOBBY}.msg"

    curl -s -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_SERVER_NAME}\", \"content\": ${MESSAGE}}" $HOOK_URL | jq -r '.id'

    if [ -n "${EXTRA}" ]; then
        "${LOCATION}/discord.sh" "${HOOK}" "${EXTRA}"
    fi
fi

