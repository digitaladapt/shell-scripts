#!/usr/bin/env bash

locations="$@"

# load in defaults from config
scriptRoot="$(dirname "$0")/.."
configFile="${scriptRoot}/config.sh"
if [[ -f "${configFile}" ]]; then
    source "${configFile}"

    if [[ -z "${locations}" ]]; then
        locations=${STORAGE_MONITOR[@]}
    fi
fi

warn=false
messages=()
for index in "${!STORAGE_ALERT[@]}"; do
    storage=$("${scriptRoot}/storage.sh" "${index}" "${STORAGE_ALERT[$index]}")
    alert="$?"

    if [[ '0' != "${alert}" ]]; then
        warn=true
        messages+=("${storage} is below threshold ${STORAGE_ALERT[$index]}G")
    else
        messages+=("${storage} is above threshold ${STORAGE_ALERT[$index]}G")
    fi
done

if [[ "${warn}" = true ]]; then
    color='purple'
    title='Storage Alert'
    touch "${HOME}/.storage.alert"
elif [[ -f "${HOME}/.storage.alert" ]]; then
    color='blue'
    title='Storage Alert Resolved'
    rm "${HOME}/.storage.alert"
else
    # no storage alerts, exit quietly
    exit 0
fi

printf "%s\n" "${messages[@]}" | "${scriptRoot}/discord.sh" -a -c "${color}" -t "${title}"

