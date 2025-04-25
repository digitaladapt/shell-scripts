#!/usr/bin/env bash

# determine if show all or not, default to not
all=""
if [[ "$1" == "-a" ]] || [[ "$1" == "--all" ]]; then
    all="--all"
fi

if [[ -n `groups | grep 'docker'` ]]; then
    docker ps $all --format='table {{.Names}}\t{{.Status}}' | grep -v 'NAMES' | sort
elif [[ -n `groups | grep 'sudo'` ]]; then
    sudo docker ps $all --format='table {{.Names}}\t{{.Status}}' | grep -v 'NAMES' | sort
else
    echo 'User lacks docker permission'
fi

