#!/usr/bin/env bash

called_backup=false
called_update=false
curdate=$(date '+%Y-%m-%d')
script_dir=$(dirname "$0")
show_note=false
# absolute path to this scripts parent directory (package root)
package_dir=$(readlink -f "$0" | xargs dirname | xargs dirname)

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

# call this function before editing bashrc, will only make backup if needed
function make_bashrc_backup () {
    if [ "${called_backup}" = false ]; then
        called_backup=true
        if [[ ! -f "${HOME}/bashrc.backup.${curdate}" ]]; then
            echo 'backing up existing bashrc'
            cp "${HOME}/.bashrc" "${HOME}/bashrc.backup.${curdate}"
        fi
    fi
}

# ----------------------------------------------------------

read -p 'Configure PATH for scripts in this package? [y/N]: ' response
case "${response}" in
    [Yy]* )
        make_bashrc_backup
        ( cat << BASHRC

# ABS include shell scripts
export PATH="${package_dir}:\$PATH"

BASHRC
) >> "${HOME}/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

install_collection 'core utilities: (curl, python3, jq, htop, etc.)' curl git htop jq grep gzip net-tools goaccess dnsutils bash-completion cron vim make chrony build-essential gcc inotify-tools python3 python-is-python3 screen bc

# ----------------------------------------------------------

install_collection 'extra utilities: (ncdu, zip, php, rclone, etc.)' ncdu zip unzip iftop colorized-logs php-cli php-curl ca-certificates gnupg lsb-release rclone

# ----------------------------------------------------------

if [[ -n $(command -v 'php') ]]; then
    read -p 'Install PHP Composer? [y/N]: ' response
    case "${response}" in
        [Yy]* )
            return_dir=$(pwd)
            cd "${package_dir}"
            "${package_dir}/composer-install/composer-install.sh"
            if [[ -f 'composer.phar' ]]; then
                sudo mv composer.phar /usr/bin/composer
            fi
            cd "${return_dir}"
            ;;
        * )
            echo 'Skipping'
            ;;
    esac
    echo ''
fi

# ----------------------------------------------------------

read -p 'Install Docker? [y/N]: ' response
case "${response}" in
    [Yy]* )
        "${script_dir}/../docker-install/docker-install.sh"
		sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

if [[ -n $(command -v 'docker') ]]; then
    read -p 'Add user to docker group? [y/N]: ' response
    case "${response}" in
        [Yy]* )
            sudo groupadd docker
            sudo usermod -aG docker "${USER}"
            show_note=true
            ;;
        * )
            echo 'Skipping'
            ;;
    esac
    echo ''
fi

# ----------------------------------------------------------

install_collection 'Ruby: (ruby, build-essential)' ruby-full build-essential zlib1g-dev

# ----------------------------------------------------------

if [[ -n $(command -v 'ruby') ]]; then
    read -p 'Configure GEM_HOME and PATH for Ruby support? [y/N]: ' response
    case "${response}" in
        [Yy]* )
            make_bashrc_backup
            ( cat << 'BASHRC'

# ABS configure ruby gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

BASHRC
) >> "${HOME}/.bashrc"
            ;;
        * )
            echo 'Skipping'
            ;;
    esac
    echo ''
fi

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

if [[ -n $(command -v 'npm') ]]; then
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
fi

# ----------------------------------------------------------

read -p 'Install GoLang? [y/N]: ' response
case "${response}" in
    [Yy]* )
        make_bashrc_backup
        if [[ -z $(command -v 'curl') ]] || [[ -z $(command -v 'jq') ]]; then
            sudo apt install curl jq -y
        fi
        # load json file with version info, filter to only stable versions, take the first (newest), strip to just numeric
        version_flag=''
        go_version=$(curl --fail --silent --show-error 'https://go.dev/dl/?mode=json' | jq -r '.[] | select( .stable ) | .version' | head -n 1 | sed 's/[^0-9.]*//g')
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

if [[ -n $(command -v 'go') ]]; then
    read -p 'Install GoLang package "xcaddy"? [y/N]: ' response
    case "${response}" in
        [Yy]* )
            go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
            ;;
        * )
            echo 'Skipping'
            ;;
    esac
    echo ''
fi

# ----------------------------------------------------------

if [ "${show_note}" = true ]; then
    echo -e "\e[33myou will need to logout and back in before the 'docker' group will show up"
    echo ''
fi

if [ "${called_backup}" = true ]; then
    echo -e "\e[33mremember some changes will not take effect until you run:"
    echo -e "\e[36msource ~/.bashrc\e[m"
    echo ''
fi

