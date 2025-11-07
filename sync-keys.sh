#!/usr/bin/env bash

# syncronize authorized_keys with a Gitea instance,
# enabling all your ssh keys in your Gitea instance
# to allow connecting to your machine.

# load in defaults from config
scriptRoot=$(dirname "$0")
configFile="$scriptRoot/config.sh"
if [[ -f "$configFile" ]]; then
    source "$configFile"
else
    echo "${0} requires config file to exist"
    exit 1
fi

if [[ -z "${GITEA_TOKEN}" ]] || [[ -z "${GITEA_DOMAIN}" ]]; then
    echo "${0} requires config file to contain GITEA_DOMAIN and GITEA_TOKEN"
    exit 2
fi

# if there is a filter string, use it
jq_select=""
if [[ -n "${GITEA_FILTER}" ]]; then
    jq_select=" | select(. | contains(\"${GITEA_FILTER}\"))"
fi

# fetch current keys into new file
curl --silent -X 'GET' \
  "https://${GITEA_DOMAIN}/api/v1/user/keys?token=${GITEA_TOKEN}" \
  -H 'accept: application/json' | \
  jq -r ".[].key${jq_select}" > "${HOME}/.ssh/authorized_keys.new"

# get filesizes
oldSize=$(wc -l "${HOME}/.ssh/authorized_keys"     | cut -d ' ' -f 1)
newSize=$(wc -l "${HOME}/.ssh/authorized_keys.new" | cut -d ' ' -f 1)

# compare contents
theDiff=$(diff "${HOME}/.ssh/authorized_keys" "${HOME}/.ssh/authorized_keys.new" | grep '^[<>]')

# ensure new is not-empty, check if different, log the change, and update the file
if [[ "$newSize" -gt "0" ]] && [[ -n "$theDiff" ]]; then
    # backup existing authorized_keys, if one exists
    if [[ -f "${HOME}/.ssh/authorized_keys" ]]; then
        cp "${HOME}/.ssh/authorized_keys" "${HOME}/.ssh/authorized_keys.old"
    fi

    mv "${HOME}/.ssh/authorized_keys.new" "${HOME}/.ssh/authorized_keys"
    echo "$theDiff" | ntfy pub -T white_large_square -t "Auth-keys updated on $hostname" server-info
fi

