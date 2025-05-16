#!/usr/bin/env bash

# used by crons/thermal-*
# degrees in Celsius which we regard as too high
THERMAL_ALERT=70

# used by crons/storage-*
STORAGE_MONITOR=("/")

# used by crons/storage-alert.sh
# must declare associated array explicitly
declare -A STORAGE_ALERT
# storage in GiB
STORAGE_ALERT=(["/"]=5)

# used by cloudflare.sh, discord.sh
SERVER_DOMAIN=$(cat /etc/hostname)

# used by cloudflare.sh
# default is to only update dns records which have the comment "managed by <SERVER-HOSTNAME>"
CLOUDFLARE_TOKEN="<API_TOKEN DNS:Read, DNS:Edit>"
CLOUDFLARE_ZONE="<ZONE_ID>"
CLOUDFLARE_FILTER_PREFIX="comment.contains=managed+by+$SERVER_DOMAIN&"

# used by discord.sh
DISCORD_SERVER_NAME="$SERVER_DOMAIN"
DISCORD_TITLE_SUFFIX="· $DISCORD_SERVER_NAME"
DISCORD_GENERAL_HOOK="<WEBHOOK_URL_HERE>?wait=true"

