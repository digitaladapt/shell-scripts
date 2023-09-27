#!/bin/bash

# perform a "git fetch" on each location specified (recursively), or current location if none specified.
# git will quietly ignore any git repo stored in a folder you lack permission on.
# fetch does not effect local files, just updating information about repo from remote.
#
# will only search symbolic links when passed "-l" option, must be before any locations
# fetch-all.sh [-l] # current location implied
# fetch-all.sh [-l] ~/my-projects /var/group-projects

# check for "-l" in command prompt
followLinks="-H"
while getopts "l" option; do
    case $option in
        l)
            followLinks="-L"
            ;;
    esac
done
shift "$((OPTIND-1))"

if [[ "-H" == "$followLinks" ]]; then
    echo "use -l to follow symbolic links"
fi

# function to process each location
function process_git_fetch () {
    startedIn=`pwd`
    location=$(dirname "$@")
    echo -n "----- git fetch $location "
    printf "%*.*s" 0 $((40 - ${#location} )) "----------------------------------------"
    echo "-----"
    cd "$location"
    git fetch --tags --prune
    cd "$startedIn"
}

# find all folders named ".git" under given locations,
# and call process_git_fetch on each location that was found.
# we then work on the folder that contained the ".git" folder.

find "$followLinks" "$@" -type d -name ".git" | while read -r file; do process_git_fetch "$file"; done

