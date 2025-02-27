#!/bin/bash

echo "----- Disable IPv6 privacy settings? in sysctl -------"
read -p 'if using as a IPv6 enabled server, you probably want to turn that off? [y/N]: ' fix_tempaddr
case $fix_tempaddr in
    [Yy]* )
        echo 'Comment existing tempaddr settings'
        sudo sed -i '/^\(net.ipv6.conf.all.use_tempaddr\|net.ipv6.conf.default.use_tempaddr\)/s/^/# ABS #/' "/etc/sysctl.d/10-ipv6-privacy.conf"

        echo 'Appending replacement tempaddr settings'
        (
        cat << 'TERM'

# ABS do not use the privacy extensions
net.ipv6.conf.all.use_tempaddr = 0
net.ipv6.conf.default.use_tempaddr = 0

TERM
) | sudo tee -a "/etc/sysctl.d/10-ipv6-privacy.conf"

        echo "You should reboot to ensure the new settings go into effect"

        ;;
    * )
        echo 'Skipping'
        ;;
esac

