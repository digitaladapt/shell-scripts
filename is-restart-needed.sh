#!/usr/bin/env bash

if [ -f "/var/run/reboot-required" ]; then
    echo "----- Reboot Needed ---------------------------------"
else
    echo "----- Reboot *Not* Needed ---------------------------"
fi

