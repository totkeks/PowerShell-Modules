function New-PathAlias {
	<#
		.SYNOPSIS
			Creates a new path alias.

		.EXAMPLE
			New-PathAlias Temp $env:TEMP

			This will create an alias named 'Temp' to represent the path for tempory data.

		.LINK
			Get-PathAlias
			Remove-PathAlias
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, Position = 0)]
		[ValidateScript(
			{ (Get-PathAlias) -notcontains $_ },
			ErrorMessage = "The alias '{0}' already exists."
		)]
		[ValidateNotNullOrEmpty()]
		[string] $Name,

		[Parameter(Mandatory, Position = 1)]
		[ValidateScript(
			{ Test-Path $_ -PathType Container },
			ErrorMessage = "The path '{0}' is not a folder."
		)]
		[ValidateScript(
			{ Test-Path $_ },
			ErrorMessage = "The path '{0}' does not exist."
		)]
		[ValidateNotNullOrEmpty()]
		[string] $Path
	)

	$ProfileManagement.Aliases.Add(
		$Name,
		[PSCustomObject]@{
			PSTypeName = "ProfileManagement.PathAlias"
			Name = $Name
			Path = $Path
		}
	)
}
