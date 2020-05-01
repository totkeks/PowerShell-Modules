# Script-internal configuration object
$Script:GitManagement = @{ }

. $PSScriptRoot\GitProvider.ps1

$GitManagement.HomeDirectory = $null

# Default providers
Add-GitProvider "Azure" 'https://(?:\w+@)?dev.azure.com/(?<Organization>\w+)/(?<Project>\w+)/_git/(?<Repository>[\w-_]+)' '${Organization}/${Project}/${Repository}'
Add-GitProvider "GitHub" 'https://github\.com/(?<UserOrOrganization>\w+)/(?<Repository>[\w-_]+)\.git' '${UserOrOrganization}/${Repository}'
Add-GitProvider "Bitbucket" 'https://(?:\w+@)?bitbucket.org/(?<User>\w+)/(?<Repository>[\w-_]+)\.git' '${User}/${Repository}'
