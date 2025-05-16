#!/usr/bin/env bash

scriptRoot=$(dirname "$0")

if (( "0" == "$#" )); then
    device='/'
    "${scriptRoot}/storage.sh" "${device}"
else
    for device in "$@"; do
        "${scriptRoot}/storage.sh" "${device}"
    done
fi

