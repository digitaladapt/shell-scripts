#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/../config.sh"

cd "${BACKUP_DIRECTORY}"

backups=`find * -type f | sort | xargs du -h`
echo "${backups}"
${LOCATION}/../discord.sh general "${backups}"

hashes=`find * -type f | sort | xargs md5sum`
echo "${hashes}"
${LOCATION}/../discord.sh general "${hashes}"

