# All in one file due to class exporting / importing issues with PowerShell
# Note: Reloading the module does not provide a new instance of the class
using namespace System.Management.Automation

$GitManagement.Repositories = $null
$GitManagement.LastRepositoryScan = Get-Date

class ValidProviderGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return Get-SortedProviderNames
	}
}

function CloneGitRepository ([string]$Url, [bool]$Force) {
	$provider = Select-GitProvider $Url

	$Url -match $provider.UrlPattern | Out-Null
	$repositoryPath = Join-Path (Get-GitBaseDirectory) $provider.Name ($provider.directoryHierarchy | ForEach-Object { $Matches[$_] })

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

filter FindDotGitDirectory {
	if (Test-Path $_\.git) {
		return $_
	}

	Get-ChildItem -Directory $_ | FindDotGitDirectory
}

filter RelativePaths {
	[io.path]::GetRelativePath((Get-GitBaseDirectory), $_.FullName)
}

function Find-GitRepositories {
	if ($null -eq $GitManagement.Repositories -or ((Get-Date) - $GitManagement.LastRepositoryScan).TotalSeconds -gt 300) {
		Write-Debug "Updating repository cache"

		$repositoryPaths = Get-GitBaseDirectory | FindDotGitDirectory | RelativePaths
		$providers = Get-GitProvider

		$GitManagement.LastRepositoryScan = Get-Date
		$GitManagement.Repositories = $repositoryPaths | ForEach-Object {
			$splitPath = $_.Split([io.path]::DirectorySeparatorChar)
			$provider = $providers | Where-Object Name -EQ $splitPath[0]
			$directories = $splitPath[1..($splitPath.Count - 1)]

			$repository = [PSCustomObject]@{
				PSTypeName = "GitManagement.GitRepository"
				Provider   = $provider.Name
			}

			$properties = [ordered]@{ }
			for ($ii = 0; $ii -lt $directories.Length; $ii++) {
				$hierarchicalDirectory = $provider.DirectoryHierarchy[$ii]
				$properties.Add($hierarchicalDirectory, $directories[$ii])
			}

			$repository | Add-Member Properties $properties
			$repository
		}
	}

	$GitManagement.Repositories
}

function Get-GitRepository {
	[CmdletBinding(DefaultParameterSetName = "List")]
	Param(
		[parameter(Position = 0, ParameterSetName = "Clone")]
		[ValidateNotNullOrEmpty()]
		[string] $Url,

		[parameter(ParameterSetName = "Clone")]
		[switch] $Force,

		[parameter(ParameterSetName = "List")]
		[ValidateNotNullOrEmpty()]
		[string] $Provider
	)

	switch ($PSCmdlet.ParameterSetName) {
		"Clone" {
			CloneGitRepository $Url $Force
		}

		Default {
			if ($Provider) {
				Find-GitRepositories | Where-Object Provider -EQ $Provider
			}
			else {
				Find-GitRepositories
			}
		}
	}
}

function Enter-GitRepository {
	Param(
		[parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Name
	)


}
