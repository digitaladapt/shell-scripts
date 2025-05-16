#!/usr/bin/env bash

# check https status code, for domain, and lookup ip address.
# check-domain.sh www.example.com [example.org]

# check for "-v" in command prompt
verbose=false
while getopts 'v' flag; do
    case "$flag" in
        v)
            verbose=true
            ;;
    esac
done
shift "$((OPTIND-1))"

if [ "$verbose" = false ]; then
    echo "use -v for verbose mode (to also get DNS TTL)"
fi

function process_domain_list () {
    for domain in "$@"; do
        # get current https status code from this domain
        curl -s -o /dev/null --connect-timeout 0.5 -I -w '%{http_code} ' "https://$domain/"

        # we lookup the name-server for the base domain, and use that as our resolver
        # TODO need to fix, as this will not work with domains like: "example.co.uk"
        basedomain=$(expr match "$domain" '.*\.\(.*\..*\)')
        if [[ -z $basedomain ]]; then
            # input may have not had a subdomain
            basedomain="$domain"
        fi
        nameserver=$(dig +short NS $basedomain | head -n 1)

        # if verbose, we show full answer, instead of just the ip (adds TTL and Record Type)
        if [ $verbose = true ]; then
            output=$(dig @$nameserver +noall +answer $domain)
            printf "%-39.39s %5.5s %-2.2s %-10.10s %-39.39s\n" $output
        else
            output=$(dig @$nameserver +short $domain)
            printf "%-39.39s %-39.39s\n" "$domain." $output
        fi
    done
}

echo "----- Domain Check -------------------------------------------"

process_domain_list "$@"

