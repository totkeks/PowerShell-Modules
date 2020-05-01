# All in one file due to class exporting / importing issues with PowerShell
# Note: Reloading the module does not provide a new instance of the class
using namespace System.Management.Automation

$GitManagement.Providers = @{ }

class ValidProviderGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return Get-SortedProviderNames
	}
}

function Get-SortedProviderNames {
	$GitManagement.Providers.Keys | Sort-Object
}

function Get-GitProvider {
	Param (
		[Parameter(Mandatory = $false, Position = 0)]
		[ValidateSet(
			[ValidProviderGenerator],
			ErrorMessage = "The provider '{0}' does not exist."
		)]
		[string] $Name
	)

	if ($Name) {
		return $GitManagement.Providers[$Name]
	}

	Get-SortedProviderNames
}

function Add-GitProvider {
	Param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript(
			{ (Get-GitProvider) -notcontains $_ },
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

	$GitManagement.Providers.Add(
		$Name,
		@{
			Name        = $Name
			UrlPattern  = $UrlPattern
			PathPattern = $PathPattern
		}
	)
}

function Remove-GitProvider {
	Param (
		[Parameter(Mandatory)]
		[ValidateSet([ValidProviderGenerator])]
		[string] $Name
	)

	$GitManagement.Providers.Remove($Name)
}

