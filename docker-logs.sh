#!/usr/bin/env bash

if [[ -n $(groups | grep 'docker') ]]; then
    docker ps -q | xargs -L 1 -P `docker ps | wc -l` docker logs --since 60s -f
elif [[ -n $(groups | grep 'sudo') ]]; then
    sudo ls /dev/null
    sudo docker ps -q | xargs -L 1 -P `sudo docker ps | wc -l` sudo docker logs --since 60s -f
else
    echo 'User lacks docker permission'
fi

