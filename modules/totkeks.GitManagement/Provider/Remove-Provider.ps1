using module ..\Generators\ConfiguredProvidersGenerator.psm1

function Remove-Provider {
	<#
		.SYNOPSIS
			Removes a git hosting provider from the configuration.

		.EXAMPLE
			Remove-Provider GitHub

			This will remove the 'GitHub' provider from to the configuration.

		.LINK
			Add-Provider
			Get-Provider
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[ValidateSet(
			[ConfiguredProvidersGenerator],
			ErrorMessage = "The provider '{0}' does not exist."
		)]
		[string] $Name
	)

	$GitManagement.Providers.Remove($Name)
}
