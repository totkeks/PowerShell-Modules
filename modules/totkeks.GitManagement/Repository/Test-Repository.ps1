function Test-Repository {
	[CmdletBinding()]
	Param (
		[Parameter()]
		[ValidateScript(
			{ Test-Path $_ -PathType Container },
			ErrorMessage = "The path '{0}' is not a folder."
		)]
		[ValidateScript(
			{ Test-Path $_ },
			ErrorMessage = "The path '{0}' does not exist."
		)]
		[ValidateNotNullOrEmpty()]
		[string] $Path = (Get-Location)
	)

	Push-Location $Path
	$result = (git rev-parse --is-inside-work-tree) -eq "true"
	Pop-Location

	$result
}
