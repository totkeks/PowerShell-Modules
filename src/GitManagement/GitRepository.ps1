function CloneGitRepository ([string]$Url, [bool]$Force) {
	$provider = Select-GitProvider $Url
	$repositoryPath = $Url -replace $provider.UrlPattern, $provider.PathPattern
	$repositoryPath = Join-Path (Get-GitBaseDirectory) $provider.Name $repositoryPath

	Write-Host "Resolved target directory as '$repositoryPath'."

	if (Test-Path $repositoryPath) {
		if ($Force) {
			Write-Host "Removing existing target directory."
			Remove-Item -Recurse -Force $repositoryPath
		}
		else {
			Write-Error "Target directory already exists. Use -Force to overwrite."
		}
	}

	git.exe clone $Url $repositoryPath
}

function Get-GitRepository {
	Param(
		[parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Url,

		[switch] $Force
	)

	CloneGitRepository($Url, $Force)
}

