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
# CMD> powershell.exe -File .\Discord.ps1 -message "Here is some content to send to Discord."
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
    [string] $distinct,
    [string] $webhook,
    [string] $botName
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
    }

    # load internal function
    . "$PSScriptRoot\\SendDiscordChunk.ps1"
}
process {
    # build up the full message
    foreach ($line in $message) {
        if ($chunk.length + $line.length -gt 1800) {
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

    if ($distinct) {
        $distinctFile = "$PSScriptRoot\\distinct\\$distinct.msg"
        if (Test-Path -Path $distinctFile) {
            [string[]] $oldMessage = Get-Content -Path $distinctFile
        }
    }

    if (($oldMessage -join "`n") -ne ($message -join "`n")) {
        # finally send each chunk of the message
        foreach ($chunk in $chunks) {
            SendDiscordMessage -message $chunk -webhook $webhook -botName $botName
        }

        # if distinct, store the updated message for future checking
        if ($distinct) {
            Out-File -FilePath $distinctFile -InputObject $message
        }
    }
}

