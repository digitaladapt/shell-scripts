#!/bin/bash

quiet=false
dryrun=false

print_usage() {
    echo '"-t": test (dry-run) flag, display what would be updated, without committing the change'
    echo '"-q": quiet flag, to suppress "already set to" messages'
    echo '"-f": query filters, see: https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-list-dns-records#Query-Parameters'
    echo 'when using regular expressions, use "\1" for first capture group, no look-forward or look-behind, nor non-greedy wildcards'
    echo 'content can use the following tags: <a> <a:example.com> <aaaa> and <aaaa:example.com> which will be replaced with equivalent ip address, each domain tag can be used once'
    echo "Usage: [token=<token-config-override>] [zone=<zone-config-override>] [prefix=<filter-prefix-override>] $0 [-q] [-f 'query-filters'] ('content' | 'regex-replace' 'regex-find')"
}

# handle all arguments provided
while getopts 'f:qt' flag; do
    case "$flag" in
        f)
            filters="$OPTARG"
            ;;
        q)
            quiet=true
            ;;
        t)
            dryrun=true
            ;;
        *)
            echo "unknown option provided '$flag'"
            print_usage
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))"

content="$1"
regex="$2"

# load in defaults from config
scriptRoot=$(dirname "$0")
configFile="$scriptRoot/config.sh"
if [[ -f "$configFile" ]]; then
    source "$configFile"

    # you can have a prefix in your config, and override it for a specific call
    if [[ -z "$prefix" ]]; then
        prefix="$CLOUDFLARE_FILTER_PREFIX"
    fi
    if [[ -n "$prefix" ]]; then
        filters="$prefix$filters"
    fi
    if [[ -z "$zone" ]]; then
        zone="$CLOUDFLARE_ZONE"
    fi
    if [[ -z "$token" ]]; then
        token="$CLOUDFLARE_TOKEN"
    fi
fi

# stop if we do not have the required information
if [ -z "$zone" -o -z "$content" -o -z "$token" ]; then
    echo 'token, zone, and content are all required'
    print_usage
    exit 1
fi

# --- update content ---
# "<a>" becomes current public ipv4
if [[ "$content" = *'<a>'* ]]; then
    ipv4=$("$scriptRoot/4-public-ip.sh")
    content=$(echo "$content" | sed "s/<a>/$ipv4/g")
fi

# limit 1
# "<a:example.com>" becomes first ipv4 of given domain
if [[ "$content" = *'<a:'* ]]; then
    domain=$(echo "$content" | grep -oP '(?<=\<a:)[^>]+(?=\>)')
    ipv4=$(dig +short A "$domain" | head -n 1)
    content=$(echo "$content" | sed "s/<a:$domain>/$ipv4/g")
fi

# "<aaaa>" becomes current public ipv6
if [[ "$content" = *'<aaaa>'* ]]; then
    ipv6=$("$scriptRoot/6-public-ip.sh")
    content=$(echo "$content" | sed "s/<aaaa>/$ipv6/g")
fi

# limit 1
# "<aaaa:example.com>" becomes first ipv6 of given domain
if [[ "$content" = *'<aaaa:'* ]]; then
    domain=$(echo "$content" | grep -oP '(?<=\<aaaa:)[^>]+(?=\>)')
    ipv6=$(dig +short AAAA "$domain" | head -n 1)
    content=$(echo "$content" | sed "s/<aaaa:$domain>/$ipv6/g")
fi

# --- update regex ---
# "<a>" becomes current public ipv4
if [[ "$regex" = *'<a>'* ]]; then
    ipv4=$("$scriptRoot/4-public-ip.sh")
    regex=$(echo "$regex" | sed "s/<a>/$ipv4/g")
fi

# limit 1
# "<a:example.com>" becomes first ipv4 of given domain
if [[ "$regex" = *'<a:'* ]]; then
    domain=$(echo "$regex" | grep -oP '(?<=\<a:)[^>]+(?=\>)')
    ipv4=$(dig +short A "$domain" | head -n 1)
    regex=$(echo "$regex" | sed "s/<a:$domain>/$ipv4/g")
fi

# "<aaaa>" becomes current public ipv6
if [[ "$regex" = *'<aaaa>'* ]]; then
    ipv6=$("$scriptRoot/6-public-ip.sh")
    regex=$(echo "$regex" | sed "s/<aaaa>/$ipv6/g")
fi

# limit 1
# "<aaaa:example.com>" becomes first ipv6 of given domain
if [[ "$regex" = *'<aaaa:'* ]]; then
    domain=$(echo "$regex" | grep -oP '(?<=\<aaaa:)[^>]+(?=\>)')
    ipv6=$(dig +short AAAA "$domain" | head -n 1)
    regex=$(echo "$regex" | sed "s/<aaaa:$domain>/$ipv6/g")
fi

# --- get matching dns records ---
results=$(curl --silent --request GET \
  --url "https://api.cloudflare.com/client/v4/zones/$zone/dns_records?$filters" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $token" )

if [[ -z "$regex" ]]; then
    newContent="$content"

    if [[ -z "$newContent" ]]; then
        if [[ "$quiet" = false ]]; then
            echo 'Content calculated to blank string, stopping.'
        fi
        exit 1
    fi
fi

while read -r result; do
    if [[ -z "$result" ]]; then
        echo 'No DNS Records found to update, stopping.'
        exit 1
    fi
    # echo "$result" | jq -C '.'

    id=$(echo "$result" | jq -r '.id')
    oldContent=$(echo "$result" | jq -r '.content')
    type=$(echo "$result" | jq -r '.type')
    name=$(echo "$result" | jq -r '.name')
    if [[ -n "$regex" ]]; then
        newContent=$(echo "$oldContent" | sed -E "s/$regex/$content/g")

        if [[ -z "$newContent" ]]; then
            if [[ "$quiet" = false ]]; then
                echo 'Content calculated to blank string, skipping.'
            fi
            continue
        fi
        # echo "current '$oldContent'"
        # echo "find    '$regex'"
        # echo "replace '$content'"
        # echo "new     '$newContent'"
    fi

    if [[ "$newContent" = "$oldContent" ]]; then
        if [[ "$quiet" = false ]]; then
            echo "$type:$name is already set to '$newContent'"
        fi
    else
        echo "updating $type:$name"
        echo "now '$newContent'"
        echo "was '$oldContent'"


        if [[ "$dryrun" = true ]]; then
            echo 'true *actually just a dry-run*'
        elif [[ -z "$newContent" ]]; then
            echo 'false empty content has no effect, update skipped'
        else
            update=$(curl --silent --request PATCH \
                --url "https://api.cloudflare.com/client/v4/zones/$zone/dns_records/$id" \
                --header 'Content-Type: application/json' \
                --header "Authorization: Bearer $token" \
                --data "{\"content\": \"$newContent\"}" )

            # display if successful, and any messages
            echo "$update" | jq -r '.success,.messages[]'
        fi
    fi
done <<< $(echo "$results" | jq -c '.result[]')

