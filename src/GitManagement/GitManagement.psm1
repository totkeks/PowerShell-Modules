$Script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Script-internal configuration object
$Script:GitManagement = @{ }
$GitManagement.Providers = @{ }
$GitManagement.BaseDirectory = $null
$GitManagement.Repositories = $null
$GitManagement.LastRepositoryScan = Get-Date

# Load everything
Get-ChildItem -Recurse $PSScriptRoot *.ps1 | ForEach-Object { . $_.FullName }

# Default providers
Add-Provider Azure 'https://(?:\w+@)?dev.azure.com/(?<Organization>\w+)/(?<Project>\w+)/_git/(?<Repository>[\w-_]+)' Organization, Project, Repository
Add-Provider GitHub 'https://github\.com/(?<UserOrOrganization>\w+)/(?<Repository>[\w-_]+)\.git' UserOrOrganization, Repository
Add-Provider Bitbucket 'https://(?:\w+@)?bitbucket.org/(?<User>\w+)/(?<Repository>[\w-_]+)\.git' User, Repository
