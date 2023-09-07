#!/bin/bash

# degrees in C
THERMAL_ALERT=75

# see: /sys/class/thermal/thermal_zone*
THERMAL_ZONE=0

STORAGE_MONITOR=("/")

# must declare associated array explicitly
declare -A STORAGE_ALERT
# storage in GiB
STORAGE_ALERT=(["/"]=5)

BACKUP_DIRECTORY="/home/ubuntu/data"

# the directory with backups to cleanup
PRUNE_DIRECTORY="/home/ubuntu/data"

# what type of backups to cleanup (what to find) "*.zip" etc, or "<DIR>"
PRUNE_TYPE="<DIR>"

# when set to 0, all backups are kept
PRUNE_DOWN_TO=0

SERVER_DOMAIN="localhost"

DISCORD_SERVER_NAME="<YOUR SERVER>"

DISCORD_GENERAL_HOOK="<WEBHOOK_URL_HERE>?wait=true"

DISCORD_RESTAKE_HOOK="<WEBHOOK_URL_HERE>?wait=true"

DISCORD_THERMAL_HOOK="<WEBHOOK_URL_HERE>?wait=true"

DISCORD_STORAGE_HOOK="<WEBHOOK_URL_HERE>?wait=true"

