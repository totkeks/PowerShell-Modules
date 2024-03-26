function Set-BaseDirectory {
	<#
		.SYNOPSIS
			Sets the base directory for all git management functions.

		.EXAMPLE
			Set-BaseDirectory C:\Projects

		.LINK
			Get-BaseDirectory
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
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

	$GitManagement.BaseDirectory = (Resolve-Path $Path).Path
}
