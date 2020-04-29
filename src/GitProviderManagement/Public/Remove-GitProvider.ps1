function Remove-GitProvider {
	Param (
		[Parameter(Mandatory)]
		[string] $Name
	)

	$GitProviderManagement.Providers.Remove($Name)
}
