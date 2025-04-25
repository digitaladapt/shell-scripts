#!/usr/bin/env bash

# return to where we were when we started
STARTED_IN=`pwd`

cd ~

EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    cd "$STARTED_IN"
    exit 1
fi

php composer-setup.php --quiet
RESULT=$?
rm composer-setup.php

if [[ -f "composer.phar" ]]; then
    sudo mv composer.phar /usr/bin/composer
    echo "Composer successfully installed."
fi

cd "$STARTED_IN"
exit $RESULT

