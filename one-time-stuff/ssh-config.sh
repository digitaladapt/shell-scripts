#!/bin/bash

echo "----- Switch to secure ssh conf ---------------------"
read -p 'Install the secure "sshd_config" file? [y/N]: ' secure_ssh
case $secure_ssh in
    [Yy]* )
        LOCATION=`dirname "$0"`
        mkdir -p "/etc/ssh/sshd_config.d"
        echo 'Backing up old config'
        sudo mv "/etc/ssh/sshd_config" "/etc/ssh/sshd_config.backup"
        echo 'Copying new config files'
        sudo cp "${LOCATION}/conf/sshd_config.conf" "/etc/ssh/sshd_config.d/sshd_config.conf"
        sudo cp "${LOCATION}/conf/include.conf" "/etc/ssh/sshd_config"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

echo "----- Restart ssh now -------------------------------"
read -p 'Restart SSH to use updated config? [y/N]: ' restart_ssh
case $restart_ssh in
    [Yy]* )
        echo 'calling systemctl'
        sudo systemctl restart ssh.service
        ;;
    * )
        echo 'Skipping'
        ;;
esac

echo 'REMEMBER TO TEST SSH:'
echo 'ENSURE ROOT LOGIN BLOCKED,'
echo 'ENSURE USER ENABLED.'

