###################
# UpdateDynv6.ps1 #
###################
#
# Windows Powershell Script for updating Dynamic DNS on Dynv6.com using the
# RESTful interface. Use the windows task schedualer to automatically run.
# Will use config.ps1 for defaults, if available.
#
# Script Parameters:
# [-zone]       <string>        Optional, DNS Zone (domain name) to update, default to config.
# [-token]      <string>        Optional, HTTP Token, see: https://dynv6.com/keys#token defaults to config.
# [-netmask]    <string>        Optional, IPv6 netmask, defaults to 128.
# [-logFile]    <string|null>   Optional, filename to log to, defaults to "~\.dynv6.log", use $null to disable logging.
# [-ipv4]       <string>        Optional, IPv4 override, to skip resolving.
# [-ipv6]       <string>        Optional, IPv6 override, to skip resolving.
#
### Example
# Run from CMD or Batch file to IPv4 and IPv6 with automatic lookup:
# CMD> pwsh -File .\Dynv6.ps1 -zone "ExampleDomain.com" -token "XXXXXX"
#
###################
# Copyright 2020 Joe Herbert ( djneonc@gmail.com )
# Copyright 2023 Andrew Stowell ( andrew@digitaladapt.com )
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###################

# we need zone and token, we also accept, netmask, and overrides
param(
    [string] $zone = "",
    [string] $token = "",
    [string] $netmask = "128",
    [object] $logFile = "$env:USERPROFILE\\.dynv6.log",
    [string] $ipv4 = "",
    [string] $ipv6 = ""
)

# load in defaults from config
$configFile = "$PSScriptRoot\\Config.ps1"
if (Test-Path -Path $configFile) {
    . $configFile

    if ( ! $zone) {
        $zone = $DYNV6_ZONE
    }
    if ( ! $token) {
        $token = $DYNV6_TOKEN
    }
}

# we store ip addresses in files, so we only update when there is a change
$file4 = "$env:USERPROFILE\\.dynv6.addr4.$zone"
$file6 = "$env:USERPROFILE\\.dynv6.addr6.$zone"

# load existing ip addresses, when available
if (Test-Path -Path $file4) {
    $old4 = Get-Content -Path $file4
}
if (Test-Path -Path $file6) {
    $old6 = Get-Content -Path $file6
}

$lookup4 = [System.Uri]'https://ipinfo.io/ip'
$lookup6 = [System.Uri]'https://v6.ipinfo.io/ip'

$update4 = [System.Uri]'https://dynv6.com/api/update'
$update6 = [System.Uri]'https://dynv6.com/api/update'

[string[]] $events = New-Object string[] 0

if ($logFile) {
    $events += Get-Date
}

# lookup IPv4, will be skipped if variable already set
if ( ! $ipv4) {
    $ipv4 = Invoke-RestMethod -Method Get -Uri $lookup4
}

# lookup IPv6, will be skipped if variable already set
if ( ! $ipv6) {
    $ipv6 = Invoke-RestMethod -Method Get -Uri $lookup6
}
$ipv6 = "$ipv6/$netmask"

# update IPv4, if changed
if ($old4 -eq $ipv4) {
    $events += "IPv4 address unchanged"
} else {
    # send IPv4 address to dynv6
    $events += "Updating IPv4"
    $body = @{
       zone = $zone
       token = $token
       ipv4 = $ipv4
    }
    $events += Invoke-RestMethod -Method Get -Uri $update4 -Body $body

    # save current IPv4 address
    Out-File -FilePath $file4 -InputObject $ipv4
}

# update IPv6, if changed
if ($old6 -eq $ipv6) {
    $events += "IPv6 address unchanged"
} else {
    # send IPv6 address to dynv6
    $events += "Updating IPv6"
    $body = @{
       zone = $zone
       token = $token
       ipv6 = $ipv6
    }
    $events += Invoke-RestMethod -Method Get -Uri $update6 -Body $body

    # save current IPv6 address
    Out-File -FilePath $file6 -InputObject $ipv6
}

if ($logFile) {
    Out-File -FilePath $logFile -Append -InputObject ($events -join "`n")
}
echo ($events -join "`n")

