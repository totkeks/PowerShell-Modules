$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Script-internal configuration object
$Script:DotfileManagement = @{
	ConfigPath = "$env:USERPROFILE\.config\dotfiles.json"
	Config = $null
}

# Load all scripts belonging to this module
Get-ChildItem -Recurse $PSScriptRoot *.ps1 | ForEach-Object { . $_.FullName }
