function Get-GitProvider {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false, Position = 0)]
		# [ValidateSet([ValidProviderGenerator])]
		[string] $Name
	)

	Process {
		if ($Name) {
			return $GitProviderManagement.Providers[$Name]
		}

		$GitProviderManagement.Providers.Keys
	}
}
