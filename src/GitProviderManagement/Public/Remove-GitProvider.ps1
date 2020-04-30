function Remove-GitProvider {
	Param (
		[Parameter(Mandatory)]
		# [ValidateSet([ValidProviderGenerator])]
		[string] $Name
	)

	$GitProviderManagement.Providers.Remove($Name)
}
