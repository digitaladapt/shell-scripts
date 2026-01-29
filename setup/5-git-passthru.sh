#!/usr/bin/env bash

script_dir=$(dirname "$0")

# ----------------------------------------------------------

echo 'WARNING: This script is designed to make a "git" user on your system to allow SSH Passthrough into a docker container, such as Gitea. If you proceed and already have a git user, this will edit it.'
echo ''

read -p 'Setup "git" user as a SSH Passthrough to a docker container? [y/N]: ' response
case "$response" in
    [Yy]* )
        # continuing
        ;;
    * )
        echo 'Stopping'
        exit 0
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'What is the name of the docker container "git" should passthrough to? [gitea]: ' dockerContainer
echo ''

# ----------------------------------------------------------

echo 'default command for gitea: ""/usr/local/bin/gitea keys -e git -u %u -t %t -k %k""'
read -p 'What is the command within the docker container that will return list of authorized keys? [gitea-default]: ' dockerCommand
echo ''

# ----------------------------------------------------------

# check if "git" user already exists
groups git > /dev/null
userExists="$?"

# we need that directory to exist, if we are going to make the shell file
sudo mkdir -p /home/git

# create shell for git user, put in /usr/local/bin/git-shell
echo 'creating custom git-shell'
( cat << 'TERM'
#!/bin/sh
/usr/bin/docker exec -i --env SSH_ORIGINAL_COMMAND="$SSH_ORIGINAL_COMMAND" 'gitea' sh "$@"

TERM
) | sudo tee '/home/git/git-shell' > /dev/null

# make it executable
echo 'making custom git-shell executable'
sudo chmod +x /home/git/git-shell

# user doesn't exist yet, so create it, just the way we want it
if [[ "$userExists" -ne "0" ]]; then
    echo 'create git user (locked password, custom shell, docker group)'

    sudo useradd -d /home/git -s /home/git/git-shell -m -U -G docker git
else
    # user exists, make sure it matches our expectations
    echo 'git user already exists'

    userHome=$(grep '^git:' /etc/passwd | cut -f 6 -d :)
    if [[ "/home/git" != "$userHome" ]]; then
        echo 'moving home directory of git user to standard location'
        sudo usermod -m -d /home/git git
    fi

    userGroups=$(groups git | cut -f 2 -d :)
    if [[ "$userGroups" != *"docker"* ]]; then
        echo 'adding docker group to git user'
        sudo usermod -aG git
    fi

    userShell=$(grep '^git:' /etc/passwd | cut -f 7 -d :)
    if [[ "/home/git/git-shell" != "$userShell" ]]; then
        echo 'setting custom shell to git user'
        sudo chsh -s /home/git/git-shell git
    fi

    echo 'checking if git user is password locked'
    userStatus=$(sudo passwd -S git | cut -f 2 -d " ")
    if [[ "$userStatus" != *"L"* ]]; then
        echo 'locking password to git user'
        sudo usermod -L
    fi
fi

# use custom docker container name, if provided one
if [[ ! -z "$dockerContainer" ]]; then
    sudo sed -i "s/gitea/${dockerContainer}/g" /home/git/git-shell
fi

# update sshd config to allow the docker container to specify the list of authorized keys
echo 'configuring sshd to check docker container for authorized keys for git user'
sudo mkdir -p '/etc/ssh/sshd_config.d'
( cat << 'CONF'
Match User git
  AuthorizedKeysCommandUser git
  AuthorizedKeysCommand /usr/bin/docker exec -i gitea /usr/local/bin/gitea keys -e git -u %u -t %t -k %k

CONF
) | sudo tee '/etc/ssh/sshd_config.d/git-passthru.conf' > /dev/null

# use custom docker container name and command, if provided one
if [[ ! -z "$dockerContainer" ]] || [[ ! -z "$dockerCommand" ]]; then
    echo 'use custom container config provided'

    # comment out normal line
    sudo sed -i 's/  AuthorizedKeysCommand /  #AuthorizedKeysCommand /g' /etc/ssh/sshd_config.d/git-passthru.conf

    # fallback to defaults if not given both
    if [[ -z "$dockerContainer" ]]; then
        dockerContainer='gitea'
    fi
    if [[ -z "$dockerCommand" ]]; then
        dockerCommand='/usr/local/bin/gitea keys -e git -u %u -t %t -k %k'
    fi

    # append new line
    echo "  AuthorizedKeysCommand /usr/bin/docker exec -i $dockerContainer $dockerCommand" | sudo tee -a /etc/ssh/sshd_config.d/git-passthru.conf
fi
echo ''

# ----------------------------------------------------------

read -p 'Restart SSH to use updated config? [y/N]: ' response
case "${response}" in
    [Yy]* )
        sudo systemctl restart ssh.service
        echo -e "\e[33mremember to test ssh, ensure root login block, ensure user enabled, git gets sent into docker container"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

