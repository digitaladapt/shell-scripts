#!/usr/bin/env bash

# there are a few different ways to resolve public-ip,
# keep trying until we get a result

# dig
if [[ -n $(command -v "dig") ]]; then
    # via opendns
    address=$(dig "@resolver1.opendns.com" -4 "myip.opendns.com" "A" "+short")
    if [[ "$?" -ne "0" ]]; then
        # dig was unsuccessful
        echo "$address" 1>&2
        address=""
    fi
fi

# curl
if [[ -z "$address" ]] && [[ -n $(command -v "curl") ]]; then
    # via ipinfo.io
    address=$(curl -4 --fail --silent --show-error "https://ipinfo.io/ip")

    if [[ -z "$address" ]]; then
        # via google
        address=$(curl -4 --fail --silent --show-error "https://domains.google.com/checkip")
    fi
fi

# wget
if [[ -z "$address" ]] && [[ -n $(command -v "wget") ]]; then
    # via ipinfo.io
    address=$(wget -4 --quiet --output-document - "https://ipinfo.io/ip")

    if [[ -z "$address" ]]; then
        # via google
        address=$(wget -4 --quiet --output-document - "https://domains.google.com/checkip")
    fi
fi

if [[ -n "$address" ]]; then
    echo "$address"
else
    echo 'Tried everything, unable to resolve IP address.' 1>&2
fi

