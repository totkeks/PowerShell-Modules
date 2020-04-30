$PrivateScripts = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
$PublicScripts = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )

. $PSScriptRoot\Model\ValidProviderGenerator.ps1

Foreach ($Script in @($PrivateScripts + $PublicScripts)) {
	Try {
		. $Script.FullName
	}
	Catch {
		Write-Error "Failed to import script $($Script.FullName): $_"
	}
}

$Script:GitProviderManagement = @{ }
$GitProviderManagement.Providers = [System.Collections.Generic.SortedDictionary[string, hashtable]]::new()
$GitProviderManagement.HomeDirectory = $null

# Default providers
Add-GitProvider "Azure" 'https://(?:\w+@)?dev.azure.com/(?<Organization>\w+)/(?<Project>\w+)/_git/(?<Repository>[\w-_]+)' '${Organization}/${Project}/${Repository}'
Add-GitProvider "GitHub" 'https://github\.com/(?<UserOrOrganization>\w+)/(?<Repository>[\w-_]+)\.git' '${UserOrOrganization}/${Repository}'
Add-GitProvider "Bitbucket" 'https://(?:\w+@)?bitbucket.org/(?<User>\w+)/(?<Repository>[\w-_]+)\.git' '${User}/${Repository}'

Export-ModuleMember -Function $PublicScripts.BaseName
