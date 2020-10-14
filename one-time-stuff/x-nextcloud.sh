#!/bin/bash

LOCATION=`realpath "$0"`
LOCATION=`dirname "${LOCATION}"`
THE_PASSWD=`openssl rand -base64 40 | head -c 40`
if [[ ${#THE_PASSWD} < 40 ]]; then
    THE_PASSWD=`date +%s.%N | sha512sum | base64 | head -c 40`
    if [[ ${#THE_PASSWD} < 40 ]]; then
        echo 'Unable to generate password, no action taken'
        exit 1
    fi
fi


echo "----- Your Email Address, for Certbot ---------------"
echo "By entering your email address, you agree to the Lets Encrypt TOS"
read -p 'Email Address (leave blank to cancel): ' email_address
if [[ -z "$email_address" ]]; then
    echo 'Operation cancelled'
    exit 1
fi

echo '(Control-C to abort)'

echo "----- Where to install NextCloud --------------------"
read -p 'Install into (defaults to "/var/www/nextcloud"): ' dir_name
if [[ -z "$dir_name" ]]; then
    dir_name='/var/www/nextcloud'
fi

public_ip=`${LOCATION}/../public-ip.sh`
echo "----- Set NextCloud Domain --------------------------"
read -p "Domain (defaults to public-ip '${public_ip}'): " domain_name
if [[ -z "$domain_name" ]]; then
    domain_name="${public_ip}"
fi

echo "----- Set NextCloud Database ------------------------"
read -p 'Database schema and user names (defaults to "nextcloud"): ' database_name
if [[ -z "$database_name" ]]; then
    database_name='nextcloud'
fi

STARTED_IN=`pwd`
sudo mkdir -p "$dir_name"
sudo chown www-data:www-data "$dir_name"
sudo chmod g=u "$dir_name"
sudo chmod g+s "$dir_name"
cd "$dir_name"

echo "----- Downloading Latest NextCloud ------------------"
wget -q -O latest.tar.bz2.sha512 "https://download.nextcloud.com/server/releases/latest.tar.bz2.sha512"
wget -q -O latest.tar.bz2 "https://download.nextcloud.com/server/releases/latest.tar.bz2"
echo 'Downloading completed'

sha512sum -c --status latest.tar.bz2.sha512
RESULT=$?

if [[ "$RESULT" -ne 0 ]]; then
    echo 'NextCloud file does not match expected checksum'
    exit 1
fi

echo "----- Extracting Latest NextCloud -------------------"
tar --strip-components=1 -xjf latest.tar.bz2
rm latest.tar.bz2
rm latest.tar.bz2.sha512

echo "----- Provisioning Database -------------------------"
echo "create database ${database_name}; grant all privileges on ${database_name}.* to '${database_name}'@'localhost' identified by '${THE_PASSWD}';" | sudo mysql

echo "----- Configure the NextCloud Instance --------------"
sudo cp "${LOCATION}/conf/nextcloud.php" "${dir_name}/config/config.php"
sudo sed -i "s/DOMAIN_TO_USE/${domain_name}/g" "${dir_name}/config/config.php"
sudo sed -i "s:DATA_DIRECTORY:${dir_name}/data:g" "${dir_name}/config/config.php"
sudo sed -i "s:MYSQL_PASSWORD:${THE_PASSWD}:g" "${dir_name}/config/config.php"
sudo sed -i "s:MYSQL_NAME:${database_name}:g" "${dir_name}/config/config.php"

echo "----- Configure Nginx for NextCloud -----------------"
sudo cp "${LOCATION}/conf/nginx.conf" "/etc/nginx/sites-available/${domain_name}.conf"
sudo sed -i "s/DOMAIN_TO_USE/${domain_name}/g" "/etc/nginx/sites-available/${domain_name}.conf"
sudo sed -i "s:NEXTCLOUD_DIRECTORY:${dir_name}:g" "/etc/nginx/sites-available/${domain_name}.conf"
if [[ -f "/etc/nginx/sites-enabled/${domain_name}.conf" ]]; then
    sudo rm "/etc/nginx/sites-enabled/${domain_name}.conf"
fi
sudo ln -s "/etc/nginx/sites-available/${domain_name}.conf" "/etc/nginx/sites-enabled/${domain_name}.conf"
sudo systemctl restart nginx.service

echo "----- Certbot Secure NextCloud ----------------------"
sudo certbot --non-interactive --domain "${domain_name}" --redirect --hsts --nginx --agree-tos --email "${email_address}"
sudo systemctl restart nginx.service

echo "----- Settings File Permissions ---------------------"
sudo chown -R www-data:www-data "$dir_name"
sudo chmod -R g=u "$dir_name"
sudo chmod -R g+s "$dir_name"

cd "$STARTED_IN"

echo "----- NextCloud Is Ready ----------------------------"
echo "mysql nextcloud password:"
echo "${THE_PASSWD}"

