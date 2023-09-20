#!/bin/bash

# works consistently if you specify the -4 to force IPv4
dig -4 +short A myip.opendns.com @resolver1.opendns.com

#curl --fail --silent --show-error https://ipinfo.io/ip
#echo ""

