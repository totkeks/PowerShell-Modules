using namespace System.Collections.ObjectModel
using namespace System.Management.Automation
using module ..\Generators\ConfiguredProvidersGenerator.psm1

function New-Repository {
	<#
		.SYNOPSIS
			Creates a new git repository.

		.EXAMPLE
			New-Repository GitHub totkeks PowerShell-Modules

			This will create the 'PowerShell-Modules' repository for user 'totkeks' in the 'GitHub' provider.

		.LINK
			Get-Repository
			Enter-Repository
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, Position = 0)]
		[ValidateSet([ConfiguredProvidersGenerator])]
		[string] $Provider
	)

	DynamicParam {
		if ($Provider) {
			$dynamicParameters = [RuntimeDefinedParameterDictionary]::new()
			$position = 0

			foreach ($directory in (Get-GitProvider $Provider).DirectoryHierarchy) {
				$attribute = [ParameterAttribute]::new()
				$attribute.Mandatory = $true
				$attribute.Position = ++$position

				$attributeCollection = [Collection[System.Attribute]]::new()
				$attributeCollection.add($attribute)

				$parameter = [RuntimeDefinedParameter]::new($directory, [string], $attributeCollection)
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
