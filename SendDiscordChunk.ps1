# internal function to transmit a discord chunk
function SendDiscordMessage
{
    param (
        [string] $message = $(throw "-message is required"),
        [string] $webhook = $(throw "-webhook is required"),
        [string] $botName = $(throw "-botName is required")
    )

    # force utf-8, because that is what Discord needs
    $OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

    $header = "Content-Type: application/json"

    # convert string into json, escaping the given message
    $message = ConvertTo-Json -InputObject $message
    $botName = ConvertTo-Json -InputObject $botName

    # rewrite json string, because "\u001b[m" needs to "\u001b[0m" instead
    # windows is fine with the missing zero, but discord needs it
    $message = $message -Replace "\\u001b\[m", "\u001b[0m"

    # remove wrapping quotes around json string, replace with color-enabled block quotes
    $message = '"```ansi\n' + $message.SubString(1, $message.length - 2) + '\n```"'

    # {"username": "$botName", "content": "$message"}
    $content = "{";
    if ($botName) {
        $content += '"username": ' + $botName + ', ';
    }
    $content += '"content": ' + $message + '}';

    echo "$content" | curl.exe -s -H "$header" -X "POST" -d "@-" "$webhook" | ConvertFrom-Json | Select-Object -Property id | Out-Host
}

