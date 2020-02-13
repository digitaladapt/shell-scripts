#!/bin/bash
# perform a "git fetch" on each location specified (recursively), or current location if none specified.
# will quietly ignore any git repo stored in a folder you lack permission on.
# fetch-all.sh # current location implied
# fetch-all.sh ~/my-projects /var/group-projects

function process_git_fetch () {
    STARTED_IN=`pwd`
    for location in "$@"; do
        echo -n "----- git fetch $location "
        printf "%*.*s" 0 $((40 - ${#location} )) "----------------------------------------"
        echo "-----"
        cd "$location"
        git fetch --prune
    done
    cd "$STARTED_IN"
}

# find all folders named ".git" under given locations,
# and call process_git_fetch on each location that was found.
# only works because you can fetch while inside the ".git" folder (can not git status).

find "$@" -type d -name ".git" 2> /dev/null | while read file; do process_git_fetch "$file"; done
