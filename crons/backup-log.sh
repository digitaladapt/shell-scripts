#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/../config.sh"

cd "${BACKUP_DIRECTORY}"

backups=`find * -type f | sort | xargs du -h`
echo "${backups}"
${LOCATION}/../discord.sh block "${backups}"

hashes=`find * -type f | sort | xargs md5sum --tag`
echo "${hashes}"
${LOCATION}/../discord.sh block "${hashes}"

