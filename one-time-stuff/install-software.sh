#!/bin/bash
# install common software, will prompt before each step

echo "----- Use nginx straight from nginx.org -------------"
read -p 'Add nginx.org to apt source list? [y/N]: ' add_nginx
case $add_nginx in
    [Yy]* )
        echo 'Adding nginx.org'
        # check that such a distro/release exists on nginx.org
        distro=`lsb_release -i -s | tr '[:upper:]' '[:lower:]'`
        release=`lsb_release -c -s`
        http_code=`curl -s -o /dev/null --connect-timeout 0.5 -I -w "%{http_code}" "https://nginx.org/packages/$distro/dists/$release/nginx/"`
        if [[ "$http_code" == "200" ]]; then
            (
            cat << NGINX
deb https://nginx.org/packages/$distro/ $release nginx
deb-src https://nginx.org/packages/$distro/ $release nginx
NGINX
) | sudo tee /etc/apt/sources.list.d/nginx.list

            curl -L https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
        else
            echo "nginx.org appears to be missing $distro/$release"
        fi
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

called_update=false

function install_collection () {
    read -p "Install $1? [y/N]: " response
    case $response in
        [Yy]* )
            if [ $called_update = false ]; then
                echo "Updating APT before Installing"
                sudo apt update
                called_update=true
            fi
            echo "Installing $1"
            sudo apt install "${@:2}"
            ;;
        * )
            echo 'Skipping'
            ;;
    esac
}

# ----------------------------------------------------------

echo "----- Install core utilities: fail2bqn, git, jq.. ---"
install_collection 'extra utilities' fail2ban git htop jq grep gzip net-tools

echo "----- Install extra utilities: ncdu, zip, iftop -----"
install_collection 'extra utilities' ncdu zip unzip iftop

echo "----- Install nginx + certbot -----------------------"
install_collection 'nginx, certbot' nginx certbot python-certbot-nginx

echo "----- Add nginx logging conf ------------------------"
read -p 'Install the "tabbed_detailed" nginx log format? [y/N]: ' nginx_log
case $nginx_log in
    [Yy]* )
        LOCATION=`dirname "$0"`
        mkdir -p "/etc/nginx/conf.d"
        mkdir -p "/etc/nginx/snippets"
        sudo cp "${LOCATION}/nginx/logging.conf" "/etc/nginx/conf.d/logging.conf"
        sudo cp "${LOCATION}/nginx/cache-control.conf" "/etc/nginx/snippets/cache-control.conf"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

echo "----- Install php-fpm -------------------------------"
install_collection 'php-fpm' php-cli php-fpm php-curl php-gd php-imagick php-intl php-json php-mbstring php-mysql php-redis php-soap php-xml php-yaml php-zip

echo "----- Install redis-server --------------------------"
install_collection 'redis-server' redis-server

echo "----- Install mariadb-server ------------------------"
install_collection 'mariadb-server' mariadb-server

echo "----- Install ruby + build-essential ----------------"
install_collection 'ruby, build-essential' ruby-full build-essential zlib1g-dev

echo "----- Append ruby gems to ~/.bashrc -----------------"
read -p 'Set GEM_HOME and append path with gems/bin? [y/N]: ' add_gems
case $add_gems in
    [Yy]* )
        echo 'Appending ~/.bashrc'
        (
        cat << 'RUBY'

# Install Ruby Gems to ~/gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

RUBY
) >> "$HOME/.bashrc"

        echo "----- Done ------------------------------------------"
        echo "to take effect now, you need to run:"
        echo "source ~/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

