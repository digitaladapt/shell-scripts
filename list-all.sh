#!/bin/bash

# perform a "git remote -vv" on each location specified (recursively), or current location if none specified.
# git will quietly ignore any git repo stored in a folder you lack permission on.
# just listing where repos are located, and their remote.
#
# will only search symbolic links when passed "-l" option, must be before any locations
# will only search hidden directories when passed "-h" option, must be before any locations
# list-all.sh [-l][-h] # current location implied
# list-all.sh [-l][-h] ~/my-projects /var/group-projects

# check for "-l" and "-h" in command prompt
followLinks="-H"
checkHidden="*/.*/.git"
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
function process_git_list () {
    startedIn=`pwd`
    location=$(realpath $(dirname "$@"))
    line="--- --- --- --- --- --- --- --- ---"
    # use "--" to tell printf there are no more commands, only strings to print
    printf -- "--- git remote %s %s ---\n" "$location" "${line:${#location}}"
    cd "$location"
    git remote -vv
    cd "$startedIn"
}

# find all folders named ".git" under given locations,
# and call process_git_list on each location that was found.
# we then work on the folder that contained the ".git" folder.

find "$followLinks" "$@" -type d -name ".git" -not -path "$checkHidden" | sort | while read -r file; do process_git_list "$file"; done

