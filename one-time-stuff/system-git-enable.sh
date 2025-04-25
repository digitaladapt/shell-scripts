#!/usr/bin/env bash

# make it easy for sudo calls to have access to key scripts

# setup symlinks, if not installed in users bin directory
# need absolute path, so the symbolic links will be created correctly.
script_dir=$(readlink -f "$0" | xargs dirname | xargs dirname)


# --- git related scripts ---
if [[ ! -f "/usr/local/bin/fetch-all.sh" ]]; then
    echo 'installing fetch-all.sh'
    sudo ln -s "$script_dir/fetch-all.sh" "/usr/local/bin/fetch-all.sh"
fi

if [[ ! -f "/usr/local/bin/list-all.sh" ]]; then
    echo 'installing list-all.sh'
    sudo ln -s "$script_dir/list-all.sh" "/usr/local/bin/list-all.sh"
fi

if [[ ! -f "/usr/local/bin/pull-all.sh" ]]; then
    echo 'installing pull-all.sh'
    sudo ln -s "$script_dir/pull-all.sh" "/usr/local/bin/pull-all.sh"
fi

if [[ ! -f "/usr/local/bin/status-all.sh" ]]; then
    echo 'installing status-all.sh'
    sudo ln -s "$script_dir/status-all.sh" "/usr/local/bin/status-all.sh"
fi
