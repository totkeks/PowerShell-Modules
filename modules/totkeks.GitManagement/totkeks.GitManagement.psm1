$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ($null -eq (Get-Command "git.exe" -ErrorAction SilentlyContinue)) {
	throw "Unable to find 'git.exe' in your PATH. GitManagement module does not work without git installed."
}

# Script-internal configuration object
$Script:GitManagement = @{
	Providers = @{ }
	BaseDirectory = $null
	Repositories = $null
	LastRepositoryScan = $null
}

# Load all scripts belonging to this module
Get-ChildItem -Recurse $PSScriptRoot *.ps1 | ForEach-Object { . $_.FullName }

# Even if not a recommended verb, let's have a `clone` alias
Set-Alias -Name Clone-Repository -Value Install-Repository

# Default providers
Add-Provider Azure 'https://(?:\w+@)?dev.azure.com/(?<Organization>[\w-]+)/(?<Project>[\w-]+)/_git/(?<Repository>[\w-]+)' Organization, Project, Repository
Add-Provider GitHub 'https://github\.com/(?<UserOrOrganization>[\w-]+)/(?<Repository>[\w-]+)\.git' UserOrOrganization, Repository
Add-Provider Bitbucket 'https://(?:\w+@)?bitbucket.org/(?<User>[\w-]+)/(?<Repository>[\w-]+)\.git' User, Repository
