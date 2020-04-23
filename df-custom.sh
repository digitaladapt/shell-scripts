#!/bin/bash

LOCATION=`dirname "$0"`

if (( "0" == "$#" )); then
    device="/"
    source "${LOCATION}/storage.sh" "$device"
    exit
fi

for device in "$@"; do
    source "${LOCATION}/storage.sh" "$device"
done

