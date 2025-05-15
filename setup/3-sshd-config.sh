#!/usr/bin/env bash

script_dir=$(dirname "$0")

# ----------------------------------------------------------

read -p 'Setup secure "sshd_config" file? [y/N]: ' response
case "${response}" in
    [Yy]* )
        mkdir -p "/etc/ssh/sshd_config.d"
        sudo mv "/etc/ssh/sshd_config" "/etc/ssh/sshd_config.backup"
        sudo cp "${script_dir}/config/sshd-sshd_config.conf" "/etc/ssh/sshd_config.d/sshd_config.conf"
        sudo cp "${script_dir}/config/sshd-include.conf" "/etc/ssh/sshd_config"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Restart SSH to use updated config? [y/N]: ' response
case "${response}" in
    [Yy]* )
        sudo systemctl restart ssh.service
        echo -e "\e[33mremember to test ssh, ensure root login block, ensure user enaled"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

