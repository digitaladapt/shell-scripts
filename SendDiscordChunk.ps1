# internal function to transmit a chunk of text to Discord
function SendDiscordMessage
{
    param (
        [string] $message = $(throw "-message is required"),
        [string] $webhook = $(throw "-webhook is required"),
        [string] $botName = $(throw "-botName is required"),
        [int]    $color   = -1,
        [string] $title   = ""
    )

    # force utf-8, because that is what Discord needs
    $OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

    $header = "Content-Type: application/json"

    # convert string into json, escaping the given message
    $title   = ConvertTo-Json -InputObject $title
    $message = ConvertTo-Json -InputObject $message
    $botName = ConvertTo-Json -InputObject $botName

    # rewrite json string, because "\u001b[m" needs to "\u001b[0m" instead
    # windows is fine with the missing zero, but Discord needs it
    $message = $message -Replace "\\u001b\[m", "\u001b[0m"

    # only enable colors if needed
    $prefix = '';
    if ($message -contains "\u001b") {
        $prefix = 'ansi\n';
    }

    # remove wrapping quotes around json string, replace with color-enabled block quotes
    $message = '"```' + $prefix + $message.SubString(1, $message.length - 2) + '\n```"'

    # build post data: {"username": "$botName", "content": "$message"}
    $content = "{";
    if ($botName) {
        $content += '"username": ' + $botName + ', ';
    }
    $content += '"embeds": [{"description": ' + $message;

    if ($color -ge 0) {
        $content += ', "color": ' + $color;
    }
    if ($title) {
        $content += ', "title": ' + $title;
    }

    $content += '}]}';

    # post data is complex, so we have to pipe it into curl
    # display the resulting id/message returned from Discord
    echo "$content" | curl.exe -s -H "$header" -X "POST" -d "@-" "$webhook" | ConvertFrom-Json | Select-Object -Property id, message
}

