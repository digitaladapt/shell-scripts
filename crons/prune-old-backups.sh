#!/usr/bin/env bash

# prune the directory of matching files or subfolders,
# until we only have the desired number of backups remaining.
# assumes backups are named with something like datestamp,
# as we want to keep the bottom of the file list wheb sorted.

# pulls from config, but can take overrides:
# prune-old-backups.sh "where-to-look" "what-to-find" "how-many-to-keep"

LOCATION=`dirname "$0"`

source "${LOCATION}/../config.sh"

# directory to prune
pruneDir="$PRUNE_DIRECTORY"

# what to prune from that directory
pruneType="$PRUNE_TYPE"

# how many to keep
keepCount="$PRUNE_DOWN_TO"

if [ -n "$1" ]; then
    pruneDir="$1"    
fi

if [ -n "$2" ]; then
    pruneType=""$2
fi

if [ -n "$3" ]; then
    keepCount="$3"
fi

if (( "${keepCount}" > "0" )); then
    removeCount=0

    # find direct subfolders to remove
    if [ "${pruneType}" = "<DIR>" ]; then
        # notice the grep to remove the pruneDir from the results
        # head given a negative number will stop that much short from the bottom, so we keep those matches
        while read -r dirToRemove; do
            if [ -z "${dirToRemove}" ]; then break; fi
            removeCount=$((removeCount+1))
            echo "Removing: ${dirToRemove}"
            rm -r "${dirToRemove}"
        done <<< `find "${pruneDir}" -maxdepth 1 -type d | grep -v "^${pruneDir}$" | sort | head -n "-${keepCount}"`
    else
        # head given a negative number will stop that much short from the bottom, so we keep those matches
        while read -r fileToRemove; do
            if [ -z "${fileToRemove}" ]; then break; fi
            removeCount=$((removeCount+1))
            echo "Removing: ${fileToRemove}"
            rm "${fileToRemove}"
        done <<< `find "${pruneDir}" -type f -name "${pruneType}" | sort | head -n "-${keepCount}"`
    fi

    if (( $removeCount > 0 )); then
        echo "Successfully removed ${removeCount} extra backups."
    else
        echo 'Nothing to do, we do not have too many backups.'
    fi
else
    echo 'Nothing to do, you said keep everything.'
fi

