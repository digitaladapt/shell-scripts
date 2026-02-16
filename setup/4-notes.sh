#!/usr/bin/env bash

echo 'Next steps:'
echo '* get tailscale install script from the website and run it'
echo 'typically want to disable tailscale-dns on servers, and maybe offer as exit node:'
echo 'sudo tailscale up --login-server="https://<your-headscale-domain>" --accept-dns=false --advertise-exit-node'
echo ''
echo '* setup config.sh for shell-scripts'
echo '* setup crons for storage and thermal alerts'

