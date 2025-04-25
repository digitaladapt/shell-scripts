#!/usr/bin/env bash

backupDir="$1"
backupType="$2"

# load in defaults from config
scriptRoot="$(dirname "$0")/.."
configFile="$scriptRoot/config.sh"
if [[ -f "$configFile" ]]; then
    source "$configFile"

    if [[ -z "$backupDir" ]]; then
        backupDir="$BACKUP_DIRECTORY"
    fi
    if [[ -z "$backupType" ]]; then
        backupType="$PRUNE_TYPE"
    fi
fi

if [[ "$backupType" = "<DIR>" ]]; then
    backups=$(find "$backupDir" -maxdepth 1 -type d | grep -v "^$backupDir$" | sort | xargs du -h --summarize)
    hashes=""
else
    backups=$(find "$backupDir" -type f -name "$backupType" | sort | xargs du -h)
    hashes=$(find "$backupDir" -type f -name "$backupType" | sort | xargs md5sum --tag)
fi

echo "$backups"
if [[ -n "$hashes" ]]; then
    echo "$hashes"
fi
"$scriptRoot/discord.sh" -c "mint" -t "Backup Status" "$backups" "$hashes"

