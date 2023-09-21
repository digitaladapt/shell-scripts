#!/bin/sh

zone=$1
device=$2
scope=$3

file4="$HOME/.dynv6.addr4"
file6="$HOME/.dynv6.addr6"

[ -e $file4 ] && old4=`cat $file4`
[ -e $file6 ] && old6=`cat $file6`

# ensure we have required information
if [ -z "$zone" -o -z "$token" ]; then
    echo "Usage: token=<your-authentication-token> [netmask=64] $0 your-name.dynv6.net [device] [scope]"
    exit 1
fi

# [device] would be something like "eth0" or "wlan0"
if [ -n "$device" ]; then
    device="dev $device"
fi

# [scope] normally "global", but "link" can be useful in select proxy cases (such as wsl)
if [ -n "$scope" ]; then
    scope="scope $scope"
else
    scope="scope global"
fi

# what command should we use to call the API
if [ -e /usr/bin/curl ]; then
    bin="curl -fsS"
elif [ -e /usr/bin/wget ]; then
    bin="wget -O-"
else
    echo "neither curl nor wget found"
    exit 1
fi

# what command should we use to determine IPv4
if [ -e /usr/bin/dig ]; then
    lookup4="dig -4 +short A myip.opendns.com @resolver1.opendns.com"
else
    lookup4="$bin https://ipinfo.io/ip"
fi

# lookup IPv4
ipv4=`$lookup4`
if [ -z "$ipv4" ]; then
    echo "failed to lookup IPv4 address, continuing with 'auto'"
    ipv4="auto"
fi

# calculate IPv6
address6=$(ip -6 addr list $scope $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1)

if [ -z "$address6" ]; then
    echo "no IPv6 address found"
    exit 1
fi

if [ -z "$netmask" ]; then
    netmask="128"
fi

ipv6="$address6/$netmask"

# update IPv4, if changed
if [ "$old4" = "$ipv4" ]; then
    echo "IPv4 address unchanged"
else
    echo -n "Updating IPv4: "
    $bin "https://dynv6.com/api/update?zone=$zone&ipv4=$ipv4&token=$token"
    echo ""

    # save current address
    echo $ipv4 > $file4
fi

# update IPv6, if changed
if [ "$old6" = "$ipv6" ]; then
    echo "IPv6 address unchanged"
else
    # send addresses to dynv6
    echo -n "Updating IPv6: "
    $bin "https://dynv6.com/api/update?zone=$zone&ipv6=$ipv6&token=$token"
    echo ""

    # save current address
    echo $ipv6 > $file6
fi

