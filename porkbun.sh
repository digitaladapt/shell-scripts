#!/usr/bin/env bash

# porkbun.sh - list, update, create and delete Porkbun DNS records
# sibling to cloudflare.sh, keeping the same conventions:
#   dry-run with "-t", content tags <a> <aaaa> <a:domain> <aaaa:domain>,
#   "content" to replace wholesale or "content" + "regex" to substitute,
#   "-c" to create a record when nothing matches.
#
# api reference: https://porkbun.com/llms/porkbun-dns
# credentials:   https://porkbun.com/account/api

quiet=false
dryrun=false
listOnly=false
deleteRecords=false
matchAll=false
ttlOverride=''
nameFilter=''
typeFilter=''
jqFilter=''
createJson=''
failures=0

print_usage() {
    cat <<'USAGE'
porkbun.sh - list / update / create / delete Porkbun DNS records

  -t            test (dry-run): show what would change, write nothing
  -q            quiet: suppress "already set to" messages
  -l            list the matching records and exit
  -d            delete the matching records
  -a            match all records, ignoring the notes filter from config.sh
  -n <name>     subdomain glob to match, e.g. 'www', '*.dev', or '@' for the apex
  -y <type>     record type to match, e.g. A, AAAA, CNAME
  -f <jq>       jq predicate over the whole record, e.g. '.ttl == "600"'
  -T <ttl>      set this ttl on every record we update
  -c <json>     create this record if nothing matches, e.g.
                '{"type":"A","name":"www","content":"<a>","ttl":600}'

"content" becomes the value of every matching record. If a second positional
argument is given it is a POSIX extended regex, and content is substituted into
the current value instead of replacing it whole:

  ./porkbun.sh -n www -y A '<a>'                  set www to the public ipv4
  ./porkbun.sh -n '*' -y AAAA '<aaaa>'            every AAAA to the public ipv6
  ./porkbun.sh -n '@' -y MX 'mail.example.com' '^mail\\.'   rewrite the apex MX
  ./porkbun.sh -t -n '*' -y A '1.2.3.4'           show what would change

content and regex may use these tags, each replaceable once per domain:
  <a>                the current public ipv4
  <aaaa>             the current public ipv6
  <a:example.com>    the first ipv4 of that domain
  <aaaa:example.com> the first ipv6 of that domain

By default only records whose porkbun notes contain the text in
PORKBUN_NOTES_FILTER ("managed by <hostname>" in the example config) are
touched, so a cron job cannot wander over records somebody else owns. Use "-a"
to match everything, and note that records created with "-c" are stamped with
that note.

Variables set ahead of the command override config.sh:
  apikey=... secret=... domain=... notesFilter=... ./porkbun.sh ...
USAGE
}

# known private ranges
local4='192.168.0.0/16 172.16.0.0/12 10.0.0.0/8'
local6='fc00::/7 fe80::/10'

while getopts 'ac:df:hln:qT:ty:' flag; do
    case "$flag" in
        a)
            matchAll=true
            ;;
        c)
            createJson="$OPTARG"
            ;;
        d)
            deleteRecords=true
            ;;
        f)
            jqFilter="$OPTARG"
            ;;
        h)
            print_usage
            exit 0
            ;;
        l)
            listOnly=true
            ;;
        n)
            nameFilter="$OPTARG"
            ;;
        q)
            quiet=true
            ;;
        T)
            ttlOverride="$OPTARG"
            ;;
        t)
            dryrun=true
            ;;
        y)
            typeFilter="$OPTARG"
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

# --- config ---
scriptRoot=$(dirname "$0")
configFile="$scriptRoot/config.sh"
if [[ -f "$configFile" ]]; then
    # shellcheck source=/dev/null
    source "$configFile"

    if [[ -z "$apikey" ]]; then
        apikey="$PORKBUN_APIKEY"
    fi
    if [[ -z "$secret" ]]; then
        secret="$PORKBUN_SECRET"
    fi
    if [[ -z "$domain" ]]; then
        domain="$PORKBUN_DOMAIN"
    fi
    if [[ -z "$notesFilter" ]]; then
        notesFilter="$PORKBUN_NOTES_FILTER"
    fi
fi

apiBase="${PORKBUN_API_BASE:-https://api.porkbun.com/api/json/v3}"

# --- checks ---
if [[ -z "$apikey" || -z "$secret" || -z "$domain" ]]; then
    echo 'apikey, secret and domain are all required'
    print_usage
    exit 1
fi

if [[ "$listOnly" = false && "$deleteRecords" = false && -z "$content" && -z "$createJson" ]]; then
    echo 'content is required unless using -l, -d or -c'
    print_usage
    exit 1
fi

if [[ "$deleteRecords" = true && -z "$nameFilter" && -z "$typeFilter" && -z "$jqFilter" && "$matchAll" = false ]]; then
    # deleting with no selector at all would wipe the zone
    echo 'refusing to delete: give -n, -y, -f or -a to say which records'
    exit 1
fi

if [[ -n "$ttlOverride" && ! "$ttlOverride" =~ ^[0-9]+$ ]]; then
    echo "ttl must be an integer, got '$ttlOverride'"
    exit 1
fi

if [[ -n "$createJson" ]]; then
    if ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"$createJson"; then
        echo '-c expects a json object describing the record'
        exit 1
    fi
    if [[ -z "$(jq -r '.type // empty' <<<"$createJson")" ]]; then
        echo '-c expects at least a "type"'
        exit 1
    fi
fi

# --- api helpers ---
# apiPost <path> [extra-fields-json] [write]
# prints the response body, returns non-zero if the request could not be made
apiPost() {
    local path="$1"
    # default to an empty object so callers may omit the fields argument;
    # note "${2:-{}}" mis-parses in bash, so default in two steps
    local fields="${2:-}"
    if [[ -z "$fields" ]]; then
        fields='{}'
    fi
    local write="${3:-}"
    local body resp payload code attempt=1 max=4 wait=2 idem=''

    if ! body=$(jq -c -n --arg k "$apikey" --arg s "$secret" --argjson f "$fields" '$f + {apikey: $k, secretapikey: $s}' 2>/dev/null); then
        echo "porkbun: could not build a request body for '$path'" >&2
        return 1
    fi

    # writes get an idempotency key, so a retry after a timeout cannot apply twice
    if [[ -n "$write" ]]; then
        idem=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null || date +%s%N)
    fi

    while :; do
        if [[ -n "$idem" ]]; then
            resp=$(printf '%s' "$body" | curl --silent --show-error --max-time 60 \
                --request POST "$apiBase/$path" \
                --header 'Content-Type: application/json' \
                --header "Idempotency-Key: $idem" \
                --data @- --write-out '\n%{http_code}' 2>/dev/null)
        else
            resp=$(printf '%s' "$body" | curl --silent --show-error --max-time 60 \
                --request POST "$apiBase/$path" \
                --header 'Content-Type: application/json' \
                --data @- --write-out '\n%{http_code}' 2>/dev/null)
        fi

        code=${resp##*$'\n'}
        payload=${resp%$'\n'*}

        if [[ "$code" =~ ^(429|5[0-9][0-9])$ && $attempt -lt $max ]]; then
            echo "porkbun: '$path' returned HTTP $code, retrying in ${wait}s" >&2
            sleep "$wait"
            attempt=$((attempt + 1))
            wait=$((wait * 2))
            continue
        fi

        if [[ ! "$code" =~ ^2[0-9][0-9]$ ]]; then
            echo "porkbun: '$path' failed with HTTP ${code:-no response}" >&2
            if [[ -n "$payload" ]]; then
                printf '%s\n' "$payload" >&2
            fi
            return 1
        fi

        printf '%s\n' "$payload"
        return 0
    done
}

apiOk() {
    [[ "$(jq -r '.status // empty' 2>/dev/null <<<"$1")" == 'SUCCESS' ]]
}

# warnings never mean failure, but they do mean "this changed nothing that
# resolves", so always surface them
apiWarnings() {
    jq -r '(.warnings // [])[]' 2>/dev/null <<<"$1" | while IFS= read -r warning; do
        echo "warning: $warning" >&2
    done
}

apiError() {
    local message code
    message=$(jq -r '.message // empty' 2>/dev/null <<<"$1")
    code=$(jq -r '.code // empty' 2>/dev/null <<<"$1")
    echo "${2:-porkbun}: request failed: ${code:-ERROR} ${message}" >&2
}

isPublic() { # <address> <private-ranges>
    if [[ -n $(command -v 'grepcidr') ]]; then
        if [[ -z $(printf '%s\n' "$1" | grepcidr -v "$2") ]]; then
            return 1
        fi
    fi
    return 0
}

# --- content tags ---
expandTags() { # <value>, returns 2 if an address lookup fails
    local value="$1"
    local ipv4 ipv6 address

    if [[ "$value" == *'<a>'* ]]; then
        ipv4=$("$scriptRoot/4-public-ip.sh")
        if [[ -z "$ipv4" ]] || ! isPublic "$ipv4" "$local4"; then
            echo 'IPv4 lookup failed, stopping' >&2
            return 2
        fi
        value=${value//'<a>'/$ipv4}
    fi

    while [[ "$value" == *'<a:'* ]]; do
        address=$(printf '%s' "$value" | grep -oP '(?<=\<a:)[^>]+(?=\>)' | head -n 1)
        if [[ -z "$address" ]]; then
            break
        fi
        ipv4=$(dig +short A "$address" | head -n 1)
        if [[ -z "$ipv4" ]] || ! isPublic "$ipv4" "$local4"; then
            echo "IPv4 lookup for '$address' failed, stopping" >&2
            return 2
        fi
        value=${value//"<a:$address>"/$ipv4}
    done

    if [[ "$value" == *'<aaaa>'* ]]; then
        ipv6=$("$scriptRoot/6-public-ip.sh")
        if [[ -z "$ipv6" ]] || ! isPublic "$ipv6" "$local6"; then
            echo 'IPv6 lookup failed, stopping' >&2
            return 2
        fi
        value=${value//'<aaaa>'/$ipv6}
    fi

    while [[ "$value" == *'<aaaa:'* ]]; do
        address=$(printf '%s' "$value" | grep -oP '(?<=\<aaaa:)[^>]+(?=\>)' | head -n 1)
        if [[ -z "$address" ]]; then
            break
        fi
        ipv6=$(dig +short AAAA "$address" | head -n 1)
        if [[ -z "$ipv6" ]] || ! isPublic "$ipv6" "$local6"; then
            echo "IPv6 lookup for '$address' failed, stopping" >&2
            return 2
        fi
        value=${value//"<aaaa:$address>"/$ipv6}
    done

    printf '%s\n' "$value"
}

# --- record matching ---
matchesName() { # <subdomain>
    if [[ -z "$nameFilter" ]]; then
        return 0
    fi

    local want="$nameFilter"
    if [[ "$want" == '@' || "$want" == "$domain" ]]; then
        want=''
    elif [[ "$want" == *".$domain" ]]; then
        # a fully-qualified name means the same record as its subdomain
        want="${want%.$domain}"
    fi

    # unquoted so that globs like '*.dev' work the way a shell would
    # shellcheck disable=SC2254
    [[ "$1" == $want ]]
}

matchesType() { # <type>
    if [[ -z "$typeFilter" ]]; then
        return 0
    fi

    [[ "${1^^}" == "${typeFilter^^}" ]]
}

subdomainOf() { # <fully-qualified-name>
    if [[ "$1" == "$domain" ]]; then
        printf '\n'
    elif [[ "$1" == *".$domain" ]]; then
        printf '%s\n' "${1%.$domain}"
    else
        printf '%s\n' "$1"
    fi
}

# --- fetch the zone ---
if ! results=$(apiPost "dns/retrieve/$domain" '{}'); then
    exit 1
fi

if ! apiOk "$results"; then
    apiError "$results" "retrieving $domain"
    exit 1
fi

apiWarnings "$results"

# --- expand what we were asked to write ---
if [[ "$listOnly" = false && "$deleteRecords" = false ]]; then
    if ! content=$(expandTags "$content"); then
        exit 2
    fi

    if [[ -n "$regex" ]]; then
        if ! regex=$(expandTags "$regex"); then
            exit 2
        fi
    fi

    if [[ -z "$regex" && -z "$content" && -z "$createJson" ]]; then
        if [[ "$quiet" = false ]]; then
            echo 'Content calculated to blank string, stopping.'
        fi
        exit 1
    fi
fi

if [[ "$listOnly" = true ]]; then
    printf '%-6s %-40s %s\n' 'TYPE' 'NAME' 'CONTENT'
fi

matches=0
while IFS= read -r record; do
    if [[ -z "$record" ]]; then
        continue
    fi

    id=$(jq -r '.id // empty' <<<"$record")
    name=$(jq -r '.name // empty' <<<"$record")
    type=$(jq -r '.type // empty' <<<"$record")
    oldContent=$(jq -r '.content // empty' <<<"$record")
    ttl=$(jq -r '.ttl // empty' <<<"$record")
    prio=$(jq -r '.prio // empty' <<<"$record")
    notes=$(jq -r '.notes // empty' <<<"$record")
    subdomain=$(subdomainOf "$name")

    if ! matchesName "$subdomain"; then
        continue
    fi
    if ! matchesType "$type"; then
        continue
    fi
    if [[ "$matchAll" = false && -n "$notesFilter" ]]; then
        # shellcheck disable=SC2254
        if [[ "$notes" != *"$notesFilter"* ]]; then
            continue
        fi
    fi
    if [[ -n "$jqFilter" ]]; then
        if ! jq -e "$jqFilter" >/dev/null 2>&1 <<<"$record"; then
            continue
        fi
    fi

    matches=$((matches + 1))

    if [[ "$listOnly" = true ]]; then
        printf '%-6s %-40s %s' "$type" "$name" "$oldContent"
        if [[ -n "$prio" && "$prio" != '0' ]]; then
            printf ' (prio %s)' "$prio"
        fi
        if [[ -n "$ttl" ]]; then
            printf ' [ttl %s]' "$ttl"
        fi
        if [[ -n "$notes" ]]; then
            printf ' {%s}' "$notes"
        fi
        printf '\n'
        continue
    fi

    if [[ "$deleteRecords" = true ]]; then
        if [[ "$dryrun" = true ]]; then
            echo "would delete $type:$name '$oldContent' (id $id)"
            continue
        fi

        echo "deleting $type:$name '$oldContent'"
        if ! result=$(apiPost "dns/delete/$domain/$id" '{}' write); then
            failures=$((failures + 1))
            continue
        fi
        if apiOk "$result"; then
            apiWarnings "$result"
        else
            apiError "$result" "deleting $type:$name"
            failures=$((failures + 1))
        fi
        continue
    fi

    newContent="$content"
    if [[ -n "$regex" ]]; then
        newContent=$(printf '%s\n' "$oldContent" | sed -E "s/$regex/$content/g")
    fi

    # a blank result means the regex ate the whole value, or we were handed
    # blank content: either way writing it would break the record
    if [[ -z "$newContent" ]]; then
        if [[ "$quiet" = false ]]; then
            echo "Content calculated to blank string, skipping $type:$name."
        fi
        continue
    fi

    if [[ "$newContent" == "$oldContent" && -z "$ttlOverride" ]]; then
        if [[ "$quiet" = false ]]; then
            echo "$type:$name is already set to '$newContent'"
        fi
        continue
    fi

    echo "updating $type:$name"
    echo "now '$newContent'"
    echo "was '$oldContent'"

    if [[ "$dryrun" = true ]]; then
        echo 'true *actually just a dry-run*'
        continue
    fi

    if [[ -n "$ttlOverride" ]]; then
        fields=$(jq -c -n --arg c "$newContent" --argjson t "$ttlOverride" '{content: $c, ttl: $t}')
    else
        fields=$(jq -c -n --arg c "$newContent" '{content: $c}')
    fi

    if ! result=$(apiPost "dns/edit/$domain/$id" "$fields" write); then
        failures=$((failures + 1))
        continue
    fi
    if apiOk "$result"; then
        apiWarnings "$result"
        if [[ "$ttlOverride" = '' ]]; then
            echo 'true'
        fi
    else
        apiError "$result" "updating $type:$name"
        failures=$((failures + 1))
    fi
done < <(jq -c '(.records // [])[]' <<<"$results")

if [[ "$listOnly" = true ]]; then
    if [[ "$matches" -eq 0 ]]; then
        echo "No DNS records matched in $domain"
        exit 1
    fi
    exit 0
fi

# --- nothing matched, so maybe create ---
if [[ "$matches" -eq 0 ]]; then
    if [[ "$deleteRecords" = true ]]; then
        echo 'No DNS Records found to delete, stopping.'
        exit 1
    fi

    if [[ -z "$createJson" ]]; then
        echo 'No DNS Records found to update, stopping.'
        exit 1
    fi

    createContent=$(jq -r '.content // empty' <<<"$createJson")
    if [[ -n "$createContent" ]]; then
        if ! createContent=$(expandTags "$createContent"); then
            exit 2
        fi
    fi

    fields=$(jq -c --arg content "$createContent" '. + {content: $content}' <<<"$createJson")

    # stamp our records, so the notes filter picks them up next time
    if [[ "$matchAll" = false && -n "$notesFilter" ]]; then
        fields=$(jq -c --arg notes "$notesFilter" 'if has("notes") then . else . + {notes: $notes} end' <<<"$fields")
    fi

    createName=$(jq -r '.name // ""' <<<"$fields")
    if [[ "$createName" == '@' ]]; then
        fields=$(jq -c '.name = ""' <<<"$fields")
    fi

    if [[ "$dryrun" = true ]]; then
        echo "would create $(jq -r '.type' <<<"$fields"):$(jq -r 'if .name == "" then "@" else .name end' <<<"$fields") '$createContent'"
        echo 'true *actually just a dry-run*'
        exit 0
    fi

    if ! result=$(apiPost "dns/create/$domain" "$fields" write); then
        exit 1
    fi

    if apiOk "$result"; then
        apiWarnings "$result"
        echo "created $(jq -r '.type' <<<"$fields"):$(jq -r 'if .name == "" then "@" else .name end' <<<"$fields") (id $(jq -r '.id // "?"' <<<"$result"))"
        exit 0
    fi

    apiError "$result" "creating $(jq -r '.type' <<<"$fields") $(jq -r '.name // "@"' <<<"$fields")"
    exit 1
fi

if [[ "$failures" -gt 0 ]]; then
    echo "$failures change(s) failed" >&2
    exit 1
fi

exit 0
