#!/bin/bash
# run the given command, but only if it's not already running.
# singleton.sh long_running_script.sh --arguments --allowed

ALL="$@"

# if the exact script is not running currently, then start it
if [[ "`pgrep -f -x -c \"${ALL[@]}\"`" -eq "0" ]]; then
    LOCATION=`dirname "$0"`
    echo "[`date`] Restarting Script: $@" >> "$LOCATION/log/singleton.log"
    $1 "${@:2}"
fi

