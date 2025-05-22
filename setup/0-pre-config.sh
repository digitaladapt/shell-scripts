#!/usr/bin/env bash

read -p 'Install prerequisites (git, vim, curl, and jq)? [y/N]: ' response
case "${response}" in
    [Yy]* )
        # before we can begin, we need what should have already been installed
        sudo apt install git vim curl jq -y
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Enable available aliases within your ~/.bashrc? [y/N]: ' response
case "${response}" in
    [Yy]* )
        # enable available aliases
        sed -i -e 's/#alias/alias/g' "${HOME}/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

