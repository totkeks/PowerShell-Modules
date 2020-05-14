using module ..\Generators\ConfiguredProvidersGenerator.psm1

function Get-Provider {
	<#
		.SYNOPSIS
			Gets git hosting providers configured in the current session.

		.EXAMPLE
			Get-Provider

			This will return all providers.

		.EXAMPLE
			Get-Provider GitHub

			This will only return the 'GitHub' provider, if it exists.

		.LINK
			Add-Provider
			Remove-Provider
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false, Position = 0)]
		[ValidateSet(
			[ConfiguredProvidersGenerator],
			ErrorMessage = "The provider '{0}' does not exist."
		)]
		[string] $Name
	)

	if ($Name) {
		return $GitManagement.Providers[$Name]
	}

	$GitManagement.Providers.Values | Sort-Object Name
}
