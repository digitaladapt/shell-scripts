#!/usr/bin/env bash

if [ -f "/var/run/reboot-required" ]; then
    echo "----- Reboot Needed ---------------------------------"
    if [ $(id -u) = 0 ]; then
        reboot
    else
        sudo reboot
    fi
else
    echo "----- Reboot *Not* Needed ---------------------------"
fi

