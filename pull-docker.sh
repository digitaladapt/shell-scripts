#!/usr/bin/env bash

# perform a "docker compose pull" on each location specified (recursively), or current location if none specified.
#
# will only search symbolic links when passed "-l" option, must be before any locations
# will only search hidden directories when passed "-h" option, must be before any locations
# pull-all.sh [-l][-h] # current location implied
# pull-all.sh [-l][-h] ~/my-projects /var/group-projects

# check for "-l" and "-h" in command prompt
followLinks="-H"
checkHidden="*/.*/*compose.yaml"
while getopts "lh" option; do
    case $option in
        l)
            followLinks="-L"
            ;;
        h)
            checkHidden=""
            ;;
    esac
done
shift "$((OPTIND-1))"

if [[ "-H" == "$followLinks" ]]; then
    echo "use -l to follow symbolic links"
fi

if [[ -n "$checkHidden" ]]; then
    echo "use -h to check hidden directories"
fi

# function to process each location
function process_docker_pull () {
    startedIn=`pwd`
    location=$(realpath $(dirname "$@"))
    line="--- --- --- --- --- --- --- --- ---"
    # use "--" to tell printf there are no more commands, only strings to print
    printf -- "--- docker compose pull %s %s ---\n" "$location" "${line:${#location}}"
    cd "$location"

    # populate $runningServices[]
    mapfile -t runningServices < <(
        docker compose ps --services --status running
    )

    quietDocker=$(docker compose pull --ignore-buildable --ignore-pull-failures)

    if docker compose up -d --dry-run | grep -q "Recreate"; then
        # Only restart services that were already running
        if ((${#runningServices[@]} > 0)); then
            echo "restarting the following services: ${runningServices[@]}"
            quietDocker=$(docker compose up -d "${runningServices[@]}")
        else
            echo "updates downloaded, no services were running"
        fi
    else
        messageSuffix=""
        if ((${#runningServices[@]} > 0)); then
            messageSuffix=", services already current: ${runningServices[@]}"
        fi
        echo "no changes detected$messageSuffix"
    fi

    cd "$startedIn"
}

# find all folders named ".git" under given locations,
# and call process_git_pull on each location that was found.
# we then work on the folder that contained the ".git" folder.

find "$followLinks" "$@" -type f \( -name 'compose.yaml' -o -name 'docker-compose.yaml' \) -not -path "$checkHidden" | sort | while read -r file; do process_docker_pull "$file"; done

