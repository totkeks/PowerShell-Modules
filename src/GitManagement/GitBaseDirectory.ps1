function Set-GitBaseDirectory {
	<#
		.SYNOPSIS
			Sets the base directory for all git management functions.

		.EXAMPLE
			Set-GitBaseDirectory C:\Projects

		.LINK
			Get-GitBaseDirectory
	#>
	[CmdletBinding()]
	param(
		# The path to the new git base directory.
		[parameter(Mandatory)]
		[ValidateScript(
			{ Test-Path $_ -PathType Container },
			ErrorMessage = "The path '{0}' is not a folder."
		)]
		[ValidateScript(
			{ Test-Path $_ },
			ErrorMessage = "The path '{0}' does not exist. Use -Force to set it anyway."
		)]
		[ValidateNotNullOrEmpty()]
		[string] $Path
	)

	$GitManagement.BaseDirectory = (Resolve-Path $Path).Path
}

function Get-GitBaseDirectory {
	<#
		.SYNOPSIS
			Gets the currently configured base directory used by all git management functions.

		.EXAMPLE
			Get-GitBaseDirectory

		.LINK
			Set-GitBaseDirectory
	#>

	if (-not $GitManagement.BaseDirectory) {
		Write-Error "No git base directory set."
	}

	$GitManagement.BaseDirectory
}
