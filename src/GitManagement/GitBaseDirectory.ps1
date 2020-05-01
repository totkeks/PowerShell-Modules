$GitManagement.BaseDirectory = $null

function Set-GitBaseDirectory {
	Param(
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
	if (Test-GitBaseDirectory) {
		return $GitManagement.BaseDirectory
	}

	Write-Error "No git base directory set."
}

function Test-GitBaseDirectory {
	$null -ne $GitManagement.BaseDirectory
}

function Open-GitBaseDirectory {
	Get-GitBaseDirectory | Set-Location
}
