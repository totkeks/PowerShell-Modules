function Add-GitProvider {
	Param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Name,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $UrlPattern,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $PathPattern
	)

	if ($GitProviderManagement.Providers.ContainsKey($Name)) {
		Write-Error "The provider '$($Name)' already exists."
	}

	$GitProviderManagement.Providers.Add($Name, @{
			UrlPattern  = $UrlPattern
			PathPattern = $PathPattern
		})
}
