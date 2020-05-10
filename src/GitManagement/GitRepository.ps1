# All in one file due to class exporting / importing issues with PowerShell
# Note: Reloading the module does not provide a new instance of the class
using namespace System.Management.Automation

$GitManagement.Repositories = $null
$GitManagement.LastRepositoryScan = Get-Date

class ValidProviderGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return (Find-GitRepositories).Provider | Sort-Object | Get-Unique
	}
}

class ValidRepositoryGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return (Find-GitRepositories).Properties.Repository | Sort-Object
	}
}

class ConfiguredProvidersGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return Get-SortedProviderNames
	}
}

function Get-SortedProviderNames {
	$GitManagement.Providers.Keys | Sort-Object
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

		$baseDirectory = Get-GitBaseDirectory
		$repositoryPaths = ($baseDirectory | FindDotGitDirectory).FullName
		$providers = Get-GitProvider

		$GitManagement.LastRepositoryScan = Get-Date
		$GitManagement.Repositories = $repositoryPaths | ForEach-Object {
			$splitPath = [io.path]::GetRelativePath($baseDirectory, $_).Split([io.path]::DirectorySeparatorChar)
			$provider = $providers | Where-Object Name -EQ $splitPath[0]
			$directories = $splitPath[1..($splitPath.Count - 1)]

			$repository = [PSCustomObject]@{
				PSTypeName = "GitManagement.GitRepository"
				Provider   = $provider.Name
				Path       = $_
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
		[ValidateSet([ValidProviderGenerator])]
		[string] $Provider,

		[parameter(ParameterSetName = "List")]
		[switch] $Refresh
	)

	switch ($PSCmdlet.ParameterSetName) {
		"Clone" {
			CloneGitRepository $Url $Force
		}

		"List" {
			if ($Refresh) {
				$GitManagement.Repositories = $null
			}

			$repositories = Find-GitRepositories

			if ($Provider) {
				$repositories = $repositories | Where-Object Provider -EQ $Provider
			}

			$repositories
		}
	}
}

function Enter-GitRepository {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory)]
		[ValidateSet([ValidRepositoryGenerator])]
		[string] $Name
	)

	Set-Location (Find-GitRepositories | Where-Object { $_.Properties.Repository -eq $Name }).Path
}

function New-GitRepository {
	[CmdletBinding()]
	Param (
		[parameter(Mandatory, Position = 0)]
		[ValidateSet([ConfiguredProvidersGenerator])]
		[string] $Provider
	)

	DynamicParam {
		if ($Provider) {
			$dynamicParameters = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
			$position = 0

			foreach ($directory in (Get-GitProvider $Provider).DirectoryHierarchy) {
				$attribute = [System.Management.Automation.ParameterAttribute]::new()
				$attribute.Mandatory = $true
				$attribute.Position = ++$position

				$attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
				$attributeCollection.add($attribute)

				$parameter = [System.Management.Automation.RuntimeDefinedParameter]::new($directory, [string], $attributeCollection)
				$dynamicParameters.Add($directory, $parameter)
			}

			return $dynamicParameters
		}
	}

	Process {
		$directories = $PSBoundParameters.Values
		$repositoryPath = Join-Path (Get-GitBaseDirectory) @directories
		git init $repositoryPath
	}
}
