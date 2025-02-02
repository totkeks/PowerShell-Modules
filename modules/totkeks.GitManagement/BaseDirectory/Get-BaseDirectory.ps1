function Get-BaseDirectory {
	<#
		.SYNOPSIS
			Gets the currently configured base directory used by all git management functions.

		.EXAMPLE
			Get-BaseDirectory

		.LINK
			Set-BaseDirectory
	#>
	[CmdletBinding()]
	Param ()

	if (-not $GitManagement.BaseDirectory) {
		Write-Error "No git base directory set."
		return
	}

	$GitManagement.BaseDirectory
}
