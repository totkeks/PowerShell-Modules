function Add-GitProvider {
	Param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript(
			{ -not $GitProviderManagement.Providers.ContainsKey($_) },
			ErrorMessage = "The provider '{0}' already exists."
		)]
		[string] $Name,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $UrlPattern,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $PathPattern
	)

	$GitProviderManagement.Providers.Add(
		$Name,
		@{
			Name        = $Name
			UrlPattern  = $UrlPattern
			PathPattern = $PathPattern
		}
	)


}
