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

install_collection 'Ruby: (ruby, build-essential)' ruby-full build-essential zlib1g-dev

# ----------------------------------------------------------

read -p 'Configure GEM_HOME and PATH for Ruby support? [y/N]: ' response
case "${response}" in
    [Yy]* )
        ( cat << 'BASHRC'

# Install Ruby Gems to ~/gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

BASHRC
) >> "${HOME}/.bashrc"
        show_note=true
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Install Node.js v22? [y/N]: ' response
case "${response}" in
    [Yy]* )
        sudo "${script_dir}/../nodesource/scripts/deb/setup_lts.x"
        sudo apt install nodejs -y
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Install Node.js packages "yarn" and "http-server" globally? [y/N]: ' response
case "${response}" in
    [Yy]* )
        sudo npm install --global yarn
        sudo npm install --global http-server
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Install GoLang? [y/N]: ' response
case "${response}" in
    [Yy]* )
        sudo apt install wget jq -y
        # load json file with version info, filter to only stable versions, take the first (newest), strip to just numeric
        version_flag=''
        go_version=$(wget --quiet --output-document - 'https://go.dev/dl/?mode=json' | jq -r '.[] | select( .stable ) | .version' | head -n 1 | sed 's/[^0-9.]*//g')
        if [[ -n "${go_version}" ]]; then
            version_flag='--version'
            echo "Installing GoLand Version: ${go_version}"
        fi

        "${script_dir}/../golang-install/goinstall.sh" "${version_flag}" "${go_version}"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

if [ "${show_note}" = true ]; then
    echo -e "\e[33mremember some changes will not take effect until you run:"
    echo -e "\e[36msource ~/.bashrc\e[m"
    echo ''
fi

