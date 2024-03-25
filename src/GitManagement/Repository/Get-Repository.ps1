using module ..\Generators\ExistingProvidersGenerator.psm1

function Get-Repository {
	<#
		.SYNOPSIS
			Gets the repositories available locally or clones a new one.

		.EXAMPLE
			Get-Repository

			This will list all locally cloned repositories.

		.EXAMPLE
			Get-Repository -Provider GitHub

			This will list all repositories cloned from GitHub.

		.EXAMPLE
			Get-Repository https://github.com/totkeks/PowerShell-Modules.git

			This will clone the 'PowerShell-Modules' repository, that contains this module, from GitHub.

		.LINK
			New-Repository
			Enter-Repository
	#>
	[CmdletBinding(DefaultParameterSetName = "List")]
	Param(
		[parameter(Mandatory, Position = 0, ParameterSetName = "Clone")]
		[ValidateNotNullOrEmpty()]
		[string] $Url,

		[parameter(ParameterSetName = "Clone")]
		[switch] $Force,

		[parameter(ParameterSetName = "List")]
		[ValidateScript({
				if ($_ -notin [ExistingProvidersGenerator]::new().GetValidValues()) { throw "Not a valid value: $_" }
				$true
			})]
		[ArgumentCompleter({
				param($command, $param, $wordToComplete)
				[ExistingProvidersGenerator]::new().GetValidValues() -like "$wordToComplete*"
			})]
		[string] $Provider,

		[parameter(ParameterSetName = "List")]
		[switch] $Refresh
	)

	switch ($PSCmdlet.ParameterSetName) {
		"Clone" {
			$provider = Select-Provider $Url

			$Url -match $provider.UrlPattern | Out-Null
			$repositoryPath = Join-Path (Get-BaseDirectory) $provider.Name ($provider.directoryHierarchy | ForEach-Object { $Matches[$_] })

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

			git clone $Url $repositoryPath
		}

		"List" {
			if ($Refresh) {
				$GitManagement.Repositories = $null
			}

			$repositories = Find-Repository

			if ($Provider) {
				$repositories = $repositories | Where-Object Provider -EQ $Provider
			}

			$repositories
		}
	}
}
