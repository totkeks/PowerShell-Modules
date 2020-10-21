$Script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Load everything
Get-ChildItem -Recurse $PSScriptRoot *.ps1 | ForEach-Object { . $_.FullName }

# function Import-ModuleFromProfile {
# 	[CmdletBinding()]
# 	param (
# 		[Parameter(Mandatory)]
# 		$Name
# 	)

# 	$version = $AvailableModules | Where-Object { $_.Name.Equals($Name) } | Select-Object -First 1 -ExpandProperty Version

# 	Write-Host -NoNewline "Loading $Name installedModule version $version "
# 	Import-Module $Name -Verbose 4>&1 | ForEach-Object { Write-Host -NoNewline -ContinueLine "." }
# 	Write-Host -ContinueLine " ✓"
# }


# Prompt
# add admin icon to window title
