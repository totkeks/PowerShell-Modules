using module ..\Generators\ConfiguredAliasesGenerator.psm1

function Get-PathAlias {
	<#
		.SYNOPSIS
			Gets path aliases configured in the current session.

		.EXAMPLE
			Get-PathAlias

			This will return all aliases.

		.EXAMPLE
			Get-PathAlias Temp

			This will only return the 'Temp' alias, if it exists.

		.LINK
			New-PathAlias
			Remove-PathAlias
	#>
	[CmdletBinding()]
	Param (
		[ValidateSet(
			[ConfiguredAliasesGenerator],
			ErrorMessage = "The alias '{0}' does not exist."
		)]
		[string] $Name
	)

	if ($Name) {
		return $ProfileManagement.Aliases[$Name]
	}

	$ProfileManagement.Aliases.Values | Sort-Object Name
}
