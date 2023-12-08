#!/bin/bash

# there are a few different ways to resolve public-ip,
# keep trying until we get a result

# device info
address=$(ip -6 addr list scope global | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1)

# dig
if [[ -z "$address" ]] && [[ -n $(command -v "dig") ]]; then
    # via opendns
    address=$(dig "@resolver1.opendns.com" -6 "myip.opendns.com" "AAAA" "+short")
    if [[ "$?" -ne "0" ]]; then
        # dig was unsuccessful
        echo "$address" 1>&2
        address=""
    fi
fi

# curl
if [[ -z "$address" ]] && [[ -n $(command -v "curl") ]]; then
    # via ipinfo.io
    address=$(curl -6 --fail --silent --show-error "https://v6.ipinfo.io/ip")

    if [[ -z "$address" ]]; then
        # via google
        address=$(curl -6 --fail --silent --show-error "https://domains.google.com/checkip")
    fi
fi

# wget
if [[ -z "$address" ]] && [[ -n $(command -v "wget") ]]; then
    # via ipinfo.io
    address=$(wget -6 --quiet --output-document - "https://v6.ipinfo.io/ip")

    if [[ -z "$address" ]]; then
        # via google
        address=$(wget -6 --quiet --output-document - "https://domains.google.com/checkip")
    fi
fi

if [[ -n "$address" ]]; then
    echo "$address"
else
    echo 'Tried everything, unable to resolve IP address.' 1>&2
fi

