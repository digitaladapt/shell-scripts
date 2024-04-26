#!/bin/bash

docker ps --format='{{json .Names}}' | xargs docker inspect -f '{{range .NetworkSettings.Networks}}{{json .}}{{end}}' | jq -r '.IPAddress + " " + .Aliases[0]'

