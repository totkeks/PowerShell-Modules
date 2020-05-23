function Select-Provider {
	[CmdletBinding()]
	Param (
		[parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Url
	)

	$matchingProvider = $null

	foreach ($provider in Get-Provider) {
		if ($Url -match $provider.UrlPattern) {
			$matchingProvider = $provider
			break
		}
	}

	if ($null -eq $matchingProvider) {
		Write-Error "No provider found for repository url '$Url'."
		return
	}

	$matchingProvider
}
