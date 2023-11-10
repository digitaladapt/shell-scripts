#!/bin/bash

# discord colors are standard 6-digit hex, but converted to a base-10 integer
# colors taken from https://xkcd.com/color/rgb/
# and built into a palette based on https://sashamaps.net/docs/resources/20-colors/
#
# DARK:   maroon(#650021), brown(#653700),   olive(#6e750e),  teal(#029386),   navy(#01153e),     black(#000000),
# BRIGHT: red(#e50000),    orange(#f97306),  yellow(#ffff14), lime(#aaff32),   green(#15b01a),
#                          cyan(#00ffff),    blue(#0343df),   purple(#7e1e9c), magenta(#c20078),  grey(#929591),
# LIGHT:  pink(#ff81c0),   apricot(#ffb16d), beige(#e6daa6),  mint(#9ffeb0),   lavender(#c79fef), white(#ffffff).

skipMsg=false
declare -A colors
colors=(
    ["maroon"]=6619169 ["brown"]=6633216    ["olive"]=7238926   ["teal"]=168838    ["navy"]=70974        ["black"]=0
    ["red"]=15007744   ["orange"]=16347910  ["yellow"]=16776980 ["lime"]=11206450  ["green"]=1421338
                       ["cyan"]=65535       ["blue"]=213983     ["purple"]=8265372 ["magenta"]=12714104  ["grey"]=9606545
    ["pink"]=16744896  ["apricot"]=16757101 ["beige"]=15129254  ["mint"]=10485424  ["lavender"]=13082607 ["white"]=16777215
)

print_usage() {
    echo "Usage: $0 [-h hook-url], [-c color], [-d [distinct-name] | -t title] (message... | -z | < file.msg)"
}

# handle all arguments provided
while getopts 'h:c:d:t:z' flag; do
    case "$flag" in
        h)
            if [[ "$OPTARG" == "http"*"?wait=true" ]]; then
                hookUrl="$OPTARG"
            else
                echo "Invalid hook-url provided, should be something like:"
                echo "https://discord.com/api/webhooks/***?wait=true"
                print_usage
                exit 1
            fi
            ;;
        c)
            if [[ -v "colors[$OPTARG]" ]]; then
                color="$OPTARG"
            else
                echo "Invalid color provided, colors available:"
                echo "maroon, brown,   olive,  teal,   navy,     black,"
                echo "red,    orange,  yellow, lime,   green,"
                echo "        cyan,    blue,   purple, magenta,  grey,"
                echo "pink,   apricot, beige,  mint,   lavender, white."
                print_usage
                exit 1
            fi
            ;;
        d)
            # '-d' without value is allowed, but generates a warning
            # in which case we'll use name of parent command with arguments
            # whatever the distinct key, we clean it up, since it will be used as a filename
            # replace "/" and "|" with "_"
            if [[ -z "$OPTARG" ]]; then
                distinct=$(ps -o args= $PPID | sed 's/[\/\|]/_/g')
                echo "Warning: doing distinct by parent, with key '$distinct'" >&2
            else
                distinct=$(echo "$OPTARG" | sed 's/[\/\|]/_/g')
            fi
            ;;
        t)
            # title, for supplying a title, without activing the "distinct" feature
            title="$OPTARG"
            ;;
        z)
            skipMsg=true
            ;;
        *)
            echo "unknown option provided '$flag'"
            print_usage
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))"

# load in defaults from config
scriptRoot=$(dirname "$0")
configFile="$scriptRoot/config.sh"
if [[ -f "$configFile" ]]; then
    source "$configFile"

    botName="$DISCORD_SERVER_NAME"
    if [[ -z "$hookUrl" ]]; then
        hookUrl="$DISCORD_GENERAL_HOOK"
    fi
fi

# stop if we have no hook to send message to
if [[ -z "$hookUrl" ]]; then
    echo "Discord Hook URL must either be in config file, or supplied via '-h' argument."
    exit 1
fi

# get full message, read from arguments
message=$(echo "$@" | sed 's/^ *//' | sed 's/ *$//')

# if we have no message, read from stdin instead
if [[ -z "$message" ]] && [[ "$skipMsg" = false ]]; then
    message=$(cat - | sed 's/^ *//' | sed 's/ *$//')
fi

# sed removes blank lines from the end of the message
fullMsg=$(echo "$message" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')

# if message is too long, split it, and after curl, recursively call with remainder
# 4k max, but we must account for escaping text in json, so limit to 90% capacity
extra="${message:3600}"

if [ -n "$extra" ]; then
    message="${message:0:3600}"

    # as an added elegance, when spliting into pieces, find the last \n newline,
    # and break there instead, but only if the new smaller chunk is of sufficient size
    chunk1=$(echo "$message" | head -n -1)
    chunks=$(echo "$message" | tail -n 1)
    if (( "${#chunk1}" >= 1000 )); then
        message="$chunk1"
        extra="$chunks$extra"
    fi
fi

# sed: rewrite json string, because "\u001b[m" needs to "\u001b[0m" instead
# linux is fine with the missing zero, but discord needs it
message=$(echo "$message" | jq -aRs . | sed 's/\\u001b\[m/\\u001b[0m/g')

message="\"\`\`\`ansi\n${message:1:-1}\n\`\`\`\""

# handle distinct stuff
oldMsg=""
if [[ -n "$distinct" ]]; then
    if [[ -f "$scriptRoot/distinct/$distinct.msg" ]]; then
        oldMsg=$(cat "$scriptRoot/distinct/$distinct.msg")
    fi

    if [[ "$fullMsg" = "$oldMsg" ]]; then
        echo "duplicate message"
        exit 0
    fi

    echo "$fullMsg" > "$scriptRoot/distinct/$distinct.msg"
fi

# build content json
content="{"
if [[ -n "$botName" ]]; then
    content="$content\"username\": $(echo "$botName" | jq -aRs .), "
fi
content="$content\"embeds\":[{\"description\": "
if [[ "$skipMsg" = false ]]; then
    content="$content$message"
else
    content="$content\"\""
fi
if [[ -n "$color" ]]; then
    content="$content, \"color\": ${colors[$color]}"
fi
if [[ -n "$distinct" ]] || [[ -n "$title" ]]; then
    content="$content, \"title\": $(echo "${distinct-$title}" | jq -aRs .)"
fi
content="$content}]}"

# actually send the message to discord
curl -s -H "Content-Type: application/json" -X POST -d "$content" "$hookUrl" | jq -r '.id,.message'

# if the message was too long, send along the rest as a separate message
if [ -n "$extra" ]; then
    script=$(basename "$0")
    args=("-h" "$hookUrl")
    # when we call again, we convert distinct into a title
    if [[ -n "$distinct" ]] || [[ -n "$title" ]]; then
        args+=("-t" "${distinct-$title}")
    fi
    if [[ -n "$color" ]]; then
        args+=("-c" "$color")
    fi
    "$scriptRoot/$script" ${args[@]} "$extra"
fi
