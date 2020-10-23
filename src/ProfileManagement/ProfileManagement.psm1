$Script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Script-internal configuration object
$Script:ProfileManagement = @{ }
$ProfileManagement.Aliases = @{ }
$ProfileManagement.ProfileDirectory = $MyInvocation.PSScriptRoot
$ProfileManagement.Checkmark = "`u{f00c}"
$ProfileManagement.LinePrefix = "`u{f101}`u{f101}`u{f101} "
$ProfileManagement.Elevated = "🔥"

# Load everything
Get-ChildItem -Recurse $PSScriptRoot *.ps1 | ForEach-Object { . $_.FullName }

# Default aliases
New-PathAlias Temp $env:TEMP
New-PathAlias AppData $env:APPDATA
New-PathAlias "`u{f7db}" $env:USERPROFILE
