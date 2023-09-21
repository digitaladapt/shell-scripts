###################
# UpdateDynv6.ps1 #
###################
# Windows Powershell Script for updating
# Dynamic DNS on Dynv6.com using the RESTful
# interface. Use the windows task schedualer
# to automatically run.
#
# !!!WARNING!!!!
# This is a Proof Of Consept script!
# The next version will be turned into a proper
# cmdlet and packed into a Posershell Module.
#
# Script Parameters:
# -zone <System.String>
#  DNS Zone (domain name) to update.
#
# -token <System.String>
#  HTTP Token. https://dynv6.com/keys#token
#
# [-logfile] <System.String>
#  Path to update log file. By default the file will be placed in:
#  $env:USERPROFILE\\DDNS_UPDATE_LOG
#
# [-isIPV6] <System.Management.Automation.SwitchParameter>
#  Attempt to update the zone using an IPV6 address.
#
### Example
# Run from CMD or Batch file to update with an IPV4:
# Powershell -ExecutionPolicy Unrestricted -File ./UpdateDynv6.ps1 -zone 'ExampleDomain.com' -token 'XXXXXXXXXXXXXXXXXXXXXXXX'
#
### Run from CMD or Batch file to update with an IPV6:
# Powershell -ExecutionPolicy Unrestricted -File ./UpdateDynv6.ps1 -zone 'ExampleDomain.com' -token 'XXXXXXXXXXXXXXXXXXXXXXXX' -isIPV6
#
###################
# Copyright 2020 Joe Herbert ( djneonc@gmail.com )
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


param(
    [string] $zone = $(throw "-zone is required"),
    [string] $token = $(throw "-token is required"),
    [string] $netmask = "128",
    [string] $logfile = "$env:USERPROFILE\\.dynv6.log"
)

$file4 = "$env:USERPROFILE\\.dynv6.addr4"
$file6 = "$env:USERPROFILE\\.dynv6.addr6"

if (Test-Path -Path $file4) {
    $old4 = Get-Content -Path $file4
} else {
    $old4 = $null
}
if (Test-Path -Path $file6) {
    $old6 = Get-Content -Path $file6
} else {
    $old6 = $null
}

$lookup4 = [System.Uri]'https://ipinfo.io/ip'
$lookup6 = [System.Uri]'https://v6.ipinfo.io/ip'

$update4 = [System.Uri]'https://dynv6.com/api/update'
$update6 = [System.Uri]'https://dynv6.com/api/update'

Get-Date | Tee-Object -FilePath $logfile -Append | Out-Host

$current4 = Invoke-RestMethod -Method Get -Uri $lookup4
$current6 = Invoke-RestMethod -Method Get -Uri $lookup6

if ($old4 -eq $current4) {
    Tee-Object -FilePath $logfile -Append -InputObject "IPv4 address unchanged" | Out-Host
} else {
    Tee-Object -FilePath $logfile -Append -InputObject "Updating IPv4" | Out-Host
    $body = @{
       zone = $zone
       token = $token
       ipv4 = $current4
    }
    Invoke-RestMethod -Method Get -Uri $update4 -Body $body | Tee-Object -FilePath $logfile -Append | Out-Host
    Out-File -FilePath $file4 -InputObject $current4
}

if ($old6 -eq $current6) {
    Tee-Object -FilePath $logfile -Append -InputObject "IPv6 address unchanged" | Out-Host
} else {
    Tee-Object -FilePath $logfile -Append -InputObject "Updating IPv6" | Out-Host
    $body = @{
       zone = $zone
       token = $token
       ipv6 = "$current6/$netmask"
    }
    Invoke-RestMethod -Method Get -Uri $update6 -Body $body | Tee-Object -FilePath $logfile -Append | Out-Host
    Out-File -FilePath $file6 -InputObject $current6
}

