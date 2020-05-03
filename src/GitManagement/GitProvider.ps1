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

	$GitManagement.Providers.Values | Sort-Object Name
}

function Add-GitProvider {
	Param (
		[Parameter(Mandatory, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript(
			{ (Get-GitProvider) -notcontains $_ },
			ErrorMessage = "The provider '{0}' already exists."
		)]
		[string] $Name,

		[Parameter(Mandatory, Position = 1)]
		[ValidateNotNullOrEmpty()]
		[ValidatePattern(
			"\(\?<Repository>",
			ErrorMessage = "The url pattern must contain the named capturing group 'Repository'."
		)]
		[string] $UrlPattern,

		[Parameter(Position = 2)]
		[ValidateNotNullOrEmpty()]
		[string[]] $DirectoryHierarchy = @("Repository")
	)

	if ($DirectoryHierarchy -notcontains "Repository")	{
		Write-Error "The directory hierarchy must contain the 'Repository' element."
	}

	$GitManagement.Providers.Add(
		$Name,
		[PSCustomObject]@{
			PSTypeName         = "GitManagement.GitProvider"
			Name               = $Name
			UrlPattern         = $UrlPattern
			DirectoryHierarchy = $DirectoryHierarchy
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

function Select-GitProvider {
	Param (
		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string] $Url
	)

	$matchingProvider = $null

	foreach ($provider in Get-GitProvider) {
		if ($Url -match $provider.UrlPattern) {
			$matchingProvider = $provider
			break
		}
	}

	if ($null -eq $matchingProvider) {
		Write-Error "No provider found for repository url '$Url'."
	}

	$matchingProvider
}
