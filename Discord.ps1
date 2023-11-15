###############
# Discord.ps1 #
###############
#
# Windows Powershell Script for logging to Discord using a webhook intergration.
# Just like the bash script, except it will use config.ps1 instead of config.sh.
# Also supports skipping the send if the message is a duplicate.
#
# Script Parameters:
# -message      <string>    (Pipeline) The message you want to log into discord.
# [-distinct]   <string>    Optional, distinct name, will skip duplicate messages.
# [-webhook]    <string>    Optional, Webhook URL, defaults to config.
# [-botName]    <string>    Optional, Webhook Name, default to config.
#
### Example
# Run from CMD or Batch file to transmit the message to Discord:
# CMD> pwsh -File .\Discord.ps1 -message "Here is some content to send to Discord."
# or pipeline in powershell:
# PS1> echo "Here is some content to send to Discord" | .\Discord.ps1
#
# You can also pass the "-distinct" option to prevent duplicate messages:
# PS1> echo "same message twice" | .\Discord.ps1 -distinct "my-key"
# # message sent
# PS1> echo "same message twice" | .\Discord.ps1 -distinct "my-key"
# # duplicate message ignored
#

param (
    [parameter (ValueFromPipeline = $true)] [string[]] $message,
    [string] $distinct = "",
    [string] $webhook = "",
    [string] $botName = "",
    [string] $color   = "",
    [string] $title   = "",
    [switch] $quiet
)
begin {
    $chunk = ""
    [string[]] $chunks = New-Object string[] 0

    # load in defaults from config
    $configFile = "$PSScriptRoot\\Config.ps1"
    if (Test-Path -Path $configFile) {
        . $configFile

        if ( ! $webhook) {
            $webhook = $DISCORD_WINDOWS_HOOK
        }
        if ( ! $botName) {
            $botName = $DISCORD_SERVER_NAME
        }
        if ($title) {
            $title = "$title $DISCORD_TITLE_SUFFIX"
        }
    }

    # load internal function
    . "$PSScriptRoot\\SendDiscordChunk.ps1"
}
process {
    # build up the full message
    foreach ($line in $message) {
        if ($chunk.length + $line.length -gt 3600) {
            # if adding the line will make it too long, queue existing chunk and reset
            $chunks += $chunk
            $chunk = ""
        }
        $chunk += $line + "`n"
    }
}
end {
    # complete last chunk, by queuing it up
    $chunks += $chunk

    # if distinct, load previous message to check for duplicate message
    if ($distinct) {
        if ( ! $title) {
            $title = $distinct;
        }
        $clean = $distinct -replace '[\.\|\"\*\/\:\<\>\?\\]', '';
        $distinctFile = "$PSScriptRoot\\distinct\\$clean.msg"
        if (Test-Path -Path $distinctFile) {
            [string[]] $oldMessage = Get-Content -Path $distinctFile
        }
    }

    $colors = @{
        "maroon" = 6619169;  "brown"   = 6633216;  "olive"  = 7238926;  "teal"   = 168838;   "navy"     = 70974;    "black" = 0;
        "red"    = 15007744; "orange"  = 16347910; "yellow" = 16776980; "lime"   = 11206450; "green"    = 1421338;
                             "cyan"    = 65535;    "blue"   = 213983;   "purple" = 8265372;  "magenta"  = 12714104; "grey"  = 9606545;
        "pink"   = 16744896; "apricot" = 16757101; "beige"  = 15129254; "mint"   = 10485424; "lavender" = 13082607; "white" = 16777215;
    };

    if ($colors.ContainsKey($color)) {
        $colorNumber = $colors.$color;
    }

    if (($oldMessage -join "`n") -ne ($message -join "`n")) {
        # finally send each chunk of the message
        foreach ($chunk in $chunks) {
            # if quiet flag given, and trimmed content is empty then skip, (normally) otherwise send message
            if ($chunk.trim() || ! $quiet) {
                SendDiscordMessage -message $chunk -webhook $webhook -botName $botName -title $title -color $colorNumber
            }
        }

        # if distinct, store the updated message for future checking
        if ($distinct) {
            Out-File -FilePath $distinctFile -InputObject $message
        }
    } elseif ($distinct) {
        echo "duplicate message"
    }
}

