!/bin/bash

# degrees in C
THERMAL_ALERT=75

STORAGE_MONITOR=("/")

# must declare associated array explicitly
declare -A STORAGE_ALERT
# storage in GiB
STORAGE_ALERT=(["/"]=5)

BACKUP_DIRECTORY="/home/ubuntu/data"

# when set to 0, all backups are kept
PRUNE_DOWN_TO=0

# the directory with backups to cleanup
PRUNE_DIRECTORY="/home/ubuntu/data"

SERVER_DOMAIN="localhost"

DISCORD_SERVER_NAME="<YOUR SERVER>"

DISCORD_GENERAL_HOOK="<WEBHOOK_URL_HERE>"

DISCORD_THERMAL_HOOK="<WEBHOOK_URL_HERE>"

DISCORD_STORAGE_HOOK="<WEBHOOK_URL_HERE>"

