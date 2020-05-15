using module ..\Generators\ExistingRepositoriesGenerator.psm1

function Enter-Repository {
	<#
		.SYNOPSIS
			Enters the location of a git repository.

		.EXAMPLE
			Enter-Repository PowerShell-Modules

			This will set the current location to the 'PowerShell-Modules' repository.

		.LINK
			New-Repository
			Get-Repository
	#>
	[CmdletBinding()]
	Param(
		[parameter(Mandatory)]
		[ValidateSet([ExistingRepositoriesGenerator])]
		[string] $Name
	)

	Set-Location (Find-Repository | Where-Object { $_.Properties.Repository -eq $Name }).Path
}
