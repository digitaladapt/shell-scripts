#!/usr/bin/env bash

# perform a "git status" on each location specified (recursively), or current location if none specified.
# git will quietly ignore any git repo stored in a folder you lack permission on.
# just listing current status of repos,
#
# will only search symbolic links when passed "-l" option, must be before any locations
# will only search hidden directories when passed "-h" option, must be before any locations
# status-all.sh [-l][-h] # current location implied
# status-all.sh [-l][-h] ~/my-projects /var/group-projects

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
function process_git_status () {
    startedIn=$(pwd)
    location=$(realpath $(dirname "$@"))
    line="--- --- --- --- --- --- --- --- ---"
    # use "--" to tell printf there are no more commands, only strings to print
    printf -- "--- git status %s %s ---\n" "$location" "${line:${#location}}"
    cd "$location"
    output=""
    info=$(git -c color.status=always status)
    branch=$(git branch --show-current)
    remote=$(git remote -vv)
    upstream=$(git for-each-ref --format='%(upstream)' $(cat .git/HEAD))
    # 33 is yellow text

    # show name of branch unless on main or dev (also ignore blank '', for detached head)
    if [[ "$branch" != "" ]] && [[ "$branch" != "main" ]] && [[ "$branch" != "dev" ]]; then
        # 1;34 is bright blue
        output="$output\n[33m * [1;34m on branch '$branch' [0m"
    fi

    # display any tracking issue, 43 is yellow background
    if [[ "$remote" == "" ]]; then
        output="$output\n[33m * [30;43m no upstream repo [0m"
    elif [[ "$info" == *"HEAD detached at"* ]]; then
        output="$output\n[33m * [30;43m on detached head [0m"
    elif [[ "$upstream" == "" ]]; then
        output="$output\n[33m * [30;43m on untracked branch [0m"
    elif [[ "$info" == *"but the upstream is gone"* ]]; then
        output="$output\n[33m * [30;43m on deleted branch [0m"
    fi

    # various file statuses
    if [[ "$info" == *"Changes to be committed"* ]]; then
        # 42 is green background
        output="$output\n[33m * [0;42m has staged changes [0m"
    fi
    if [[ "$info" == *"Changes not staged for commit"* ]]; then
        # 41 is red background
        output="$output\n[33m * [0;41m has unstaged changes [0m"
    fi
    if [[ "$info" == *"Untracked files"* ]]; then
        # 31 is red text
        output="$output\n[33m * [0;31m has new files [0m"
    fi

    # various branch statuses
    if [[ "$info" == *"branch is behind"* ]]; then
        # 45 is magenta background
        output="$output\n[33m * [0;45m branch is behind [0m"
    fi
    if [[ "$info" == *"branch is ahead"* ]]; then
        # 46 is cyan background
        output="$output\n[33m * [0;46m branch is ahead [0m"
    fi
    if [[ "$info" == *"nothing to commit, working tree clean"* ]]; then
        # 90 is gray text
        output="$output\n[90m * [0;90m nothing to commit, working tree clean [0m"
    fi

    # fallback to displaying the full message
    if [[ "$output" == "" ]]; then
        output="\n$info"
    fi

    # output is prefixed with "\n", skip it
    printf "${output:2}\n"
    cd "$startedIn"
}

# find all folders named ".git" under given locations,
# and call process_git_list on each location that was found.
# we then work on the folder that contained the ".git" folder.

find "$followLinks" "$@" -type d -name ".git" -not -path "$checkHidden" | sort | while read -r file; do process_git_status "$file"; done

