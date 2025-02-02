<#
.SYNOPSIS
	Installs (clones) a remote repository.

.EXAMPLE
	Install-Repository https://github.com/totkeks/PowerShell-Modules.git

	This will clone the 'PowerShell-Modules' repository, that contains this module, from GitHub.

.LINK
	Enter-Repository
#>
function Install-Repository {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Url,

		[switch] $Force
	)

	$matchingProvider = Select-Provider $Url

	$Url -match $matchingProvider.UrlPattern | Out-Null
	$repositoryPath = Join-Path (Get-BaseDirectory) $matchingProvider.Name ($matchingProvider.directoryHierarchy | ForEach-Object { $Matches[$_] })

	Write-Host "Resolved target directory as '$repositoryPath'."

	if (Test-Path $repositoryPath) {
		if ($Force) {
			Write-Host "Removing existing target directory."
			Remove-Item -Recurse -Force $repositoryPath
		}
		else {
			Write-Error "Target directory already exists. Use -Force to overwrite."
			return
		}
	}

	git clone $Url $repositoryPath && Enter-Repository $repositoryPath
}
