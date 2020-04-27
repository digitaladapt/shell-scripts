#!/bin/bash

LOCATION=`dirname "$0"`

source "${LOCATION}/../config.sh"

# TODO: The maximum number of backups to keep (when set to 0, all backups are kept)
maxNrOfBackups="$PRUNE_DOWN_TO"

# TODO: The directory where you store the Nextcloud backups
backupMainDir="$PRUNE_DIRECTORY"

#
# Delete old backups
#
if [ ${maxNrOfBackups} != 0 ]
then
    nrOfBackups=$(ls -l ${backupMainDir} | grep -c ^d)

    if [[ ${nrOfBackups} > ${maxNrOfBackups} ]]
    then
        echo "Removing old backups..."
        ls -t ${backupMainDir} | tail -$(( nrOfBackups - maxNrOfBackups )) | while read -r dirToRemove; do
            echo "${dirToRemove}"
            rm -r "${backupMainDir}/${dirToRemove:?}"
            echo "Done"
            echo
        done
    fi
fi

