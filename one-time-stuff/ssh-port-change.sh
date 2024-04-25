#!/bin/bash

echo 'Enter the desired new port for ssh to use, leave blank to abort.'
read -p 'change ssh to operate on a different port then normal? [<new-port-number>]: ' change_port

if [[ -z "$change_port" ]]; then
    echo 'port change aborted'
else
    sudo cp "/etc/ssh/sshd_config" "/etc/ssh/sshd_config.port_backup"
    sudo sed -i '/^Port/s/^/# ABS #/' '/etc/ssh/sshd_config'
    (
    cat << CONFIG

Port $change_port

CONFIG
) | sudo tee -a /etc/ssh/sshd_config > /dev/null

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
    echo 'ENSURE YOU UPDATE YOUR CLIENT CONFIG.'
fi
