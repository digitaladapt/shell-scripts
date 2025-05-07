#!/usr/bin/env bash

called_update=false
script_dir=$(dirname "$0")

# ----------------------------------------------------------

function install_collection () {
    read -p "Install $1? [y/N]: " response
    case "${response}" in
        [Yy]* )
            if [ "${called_update}" = false ]; then
                echo 'Updating APT before Installing'
                sudo apt update
                called_update=true
            fi
            echo "Installing $1"
            sudo apt install "${@:2}" -y
            ;;
        * )
            echo 'Skipping'
            ;;
    esac
    echo ''
}

# ----------------------------------------------------------

install_collection 'core utilities: (curl, python3, jq, htop, etc.)' curl fail2ban git htop jq grep gzip net-tools goaccess dnsutils bash-completion cron vim make chrony build-essential gcc inotify-tools python3 python-is-python3 screen bc

# ----------------------------------------------------------

install_collection 'extra utilities: (ncdu, zip, php, rclone, etc.)' ncdu zip unzip iftop colorized-logs php-cli ca-certificates gnupg lsb-release rclone

# ----------------------------------------------------------

read -p 'Install Node.js v22? [y/N]: ' response
case "${response}" in
    [Yy]* )
        sudo "${script_dir}/../nodejs-install/nodesource_setup.sh"
        sudo apt install nodejs -y
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

echo "----- Install NodeJS Apps Yarn and HttpServer -------"
read -p 'Install NodeJS Apps "yarn" and "http-server" globally? [y/N]: ' node_more
case $node_more in
    [Yy]* )
        echo "----- Installing NodeJS 'yarn' globally -------------"
        sudo npm install --global yarn
        echo "----- Installing NodeJS 'http-server' globally ------"
        sudo npm install --global http-server
        echo "----- Completed NodeJS Apps -------------------------"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

echo "----- Install Go Lang -------------------------------"
read -p 'Install Go Lang? [y/N]: ' go_lang
case $go_lang in
    [Yy]* )
        echo "----- Determining current stable go version ---------"
        # load json file with version info, filter to only stable versions, take the first (newest), strip to just numeric
        go_version=$(wget --quiet --output-document - 'https://go.dev/dl/?mode=json' | jq -r '.[] | select( .stable ) | .version' | head -n 1 | sed 's/[^0-9.]*//g')
        if [[ -n "$go_version" ]]; then
            version_flag='--version'
            echo "Installing Go Version: $go_version"
        fi

        echo "----- Calling Go Install Script ---------------------"
        LOCATION=`dirname "$0"`
        "${LOCATION}/../golang-install/goinstall.sh" "$version_flag" "$go_version"
        echo "----- Completed Go Install Script -------------------"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

