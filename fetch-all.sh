#!/bin/bash
# perform a "git fetch" on each location specified
# fetch-all.sh ~/project [~/second-project]

function process_git_fetch () {
    BOB=`pwd`
    for location in "$@"; do
        if [ -d "$location/.git" ]; then
            echo -n "----- git fetch $location "
            printf "%*.*s" 0 $((40 - ${#location} )) "----------------------------------------"
            echo "-----"
            cd "$location"
            git fetch --prune
        fi
    done
    cd "$BOB"
}

process_git_fetch "$@"

