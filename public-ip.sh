#!/usr/bin/env bash

# does not always work, when you have an IPv6 connection
# dig +short A myip.opendns.com @resolver1.opendns.com

curl https://ipinfo.io/ip
echo ""

dig +short AAAA myip.opendns.com @resolver1.opendns.com

