using module ..\Generators\ConfiguredAliasesGenerator.psm1

function Remove-PathAlias {
	<#
		.SYNOPSIS
			Removes a path alias from the configuration.

		.EXAMPLE
			Remove-PathAlias Temp

			This will remove the 'Temp' alias from to the configuration.

		.LINK
			New-PathAlias
			Get-PathAlias
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[ValidateSet(
			[ConfiguredAliasesProvider],
			ErrorMessage = "The alias '{0}' does not exist."
		)]
		[string] $Name
	)

	$ProfileManagement.Aliases.Remove($Name)
}
