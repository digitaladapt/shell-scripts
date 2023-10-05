#!/bin/bash
# install common software, will prompt before each step

#echo "----- Use nginx straight from nginx.org -------------"
#read -p 'Add nginx.org to apt source list? [y/N]: ' add_nginx
#case $add_nginx in
#    [Yy]* )
#        echo 'Adding nginx.org'
#        # check that such a distro/release exists on nginx.org
#        distro=`lsb_release -i -s | tr '[:upper:]' '[:lower:]'`
#        release=`lsb_release -c -s`
#        http_code=`curl -s -o /dev/null --connect-timeout 0.5 -I -w "%{http_code}" "https://nginx.org/packages/$distro/dists/$release/nginx/"`
#        if [[ "$http_code" == "200" ]]; then
#            (
#            cat << NGINX
#deb https://nginx.org/packages/$distro/ $release nginx
#deb-src https://nginx.org/packages/$distro/ $release nginx
#NGINX
#) | sudo tee /etc/apt/sources.list.d/nginx.list
#
#            curl -L https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
#        else
#            echo "nginx.org appears to be missing $distro/$release"
#        fi
#        ;;
#    * )
#        echo 'Skipping'
#        ;;
#esac

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
            sudo apt install "${@:2}" -y
            ;;
        * )
            echo 'Skipping'
            ;;
    esac
}

# ----------------------------------------------------------

echo "----- Install core utilities: curl, vim, git, python3.. ---"
install_collection 'core utilities' curl fail2ban git htop jq grep gzip net-tools goaccess dnsutils bash-completion cron vim make chrony build-essential gcc inotify-tools python3 python-is-python3 screen bc

echo "----- Install extra utilities: ncdu, zip, iftop -----"
install_collection 'extra utilities' ncdu zip unzip iftop colorized-logs php-cli ca-certificates curl gnupg lsb-release

echo "----- Install nginx ---------------------------------"
install_collection 'nginx web-server' nginx

echo "----- Install certbot via pip, in /opt/certbot/ -----"
read -p 'Install certbot, certbot-nginx, and certbot-dns-google-domain to /opt/certbot/ via pip in virtual environment? [y/N]: ' certbot_install
case $certbot_install in
    [Yy]* )
        if [ $called_update = false ]; then
            echo "Updating APT before Installing"
            sudo apt update
            called_update=true
        fi
        echo "Installing python3-pip"
        sudo apt install python3-pip python3-venv libaugeas0 -y

        # see: https://certbot.eff.org/instructions?ws=nginx&os=pip
        sudo python3 -m venv /opt/certbot/
        sudo /opt/certbot/bin/pip install --upgrade pip
        sudo /opt/certbot/bin/pip install certbot certbot-nginx certbot-dns-google-domains
        sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
        (
        cat << 'CRON'
0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && sudo certbot renew -q
CRON
) | sudo tee -a /etc/crontab > /dev/null
        ;;
    * )
        echo 'Skipping'
        ;;
esac

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

echo "----- Install NodeJS 18 -----------------------------"
read -p 'Install NodeJS 18? [y/N]: ' node_lang
case $node_lang in
    [Yy]* )
        echo "----- Calling NodeJS Install Script -----------------"
        LOCATION=`dirname "$0"`
        sudo "${LOCATION}/../nodejs-install/nodesource_setup.sh"
        sudo apt install nodejs -y
        echo "----- Completed NodeJS Install Script ---------------"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

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
        echo "----- Calling Go Install Script ---------------------"
        LOCATION=`dirname "$0"`
        "${LOCATION}/../golang-install/goinstall.sh"
        echo "----- Completed Go Install Script -------------------"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

echo "----- Install php-fpm -------------------------------"
install_collection 'php-fpm' php-cli php-fpm php-bcmath php-curl php-gd php-gmp php-imagick imagemagick php-intl php-json php-mbstring php-mysql php-redis php-soap php-xml php-yaml php-zip

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

