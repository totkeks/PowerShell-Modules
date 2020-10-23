function Select-PathAlias {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, Position = 0)]
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

	$bestMatch = Get-PathAlias
	| Where-Object { $Path -eq "$($_.Path)" -or $Path -like "$($_.Path)*" }
	| Select-Object @{n = "Alias"; e = { $_ } }, @{n = "Length"; e = { $_.Path.Length } }
	| Sort-Object Length -Descending
	| Select-Object -First 1 -ExpandProperty Alias

	If ($bestMatch) {
		[String]($Path -replace [regex]::Escape($bestMatch.Path), $bestMatch.Name)
	}
	Else {
		$Path
	}
}
