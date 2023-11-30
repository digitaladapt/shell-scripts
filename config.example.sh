#!/bin/bash

# degrees in Celsius which we regard as too high
THERMAL_ALERT=70

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

CLOUDFLARE_TOKEN="<API_TOKEN DNS:Read, DNS:Edit>"
CLOUDFLARE_ZONE="<ZONE_ID>"
CLOUDFLARE_FILTER_PREFIX="comment.contains=managed+by+$SERVER_DOMAIN&"

DISCORD_SERVER_NAME="<YOUR_SERVER>"

DISCORD_TITLE_SUFFIX="$DISCORD_SERVER_NAME"

DISCORD_GENERAL_HOOK="<WEBHOOK_URL_HERE>?wait=true"

