using namespace System.Management.Automation

class ValidProviderGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return $Script:GitProviderManagement.Providers.Keys | Sort-Object
	}
}

function Get-GitProvider {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false, Position = 0)]
		[ValidateSet([ValidProviderGenerator])]
		[string] $Name
	)

	Process {
		if ($Name) {
			$GitProviderManagement.Providers[$Name]
		}
		else {
			[ValidProviderGenerator]::new().GetValidValues()
		}
	}
}
