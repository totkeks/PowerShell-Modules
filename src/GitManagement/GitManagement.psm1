$Script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# If git is not installed, abort the module load
if ($null -eq (Get-Command "git.exe" -ErrorAction SilentlyContinue)) {
	throw "Unable to find 'git.exe' in your PATH. GitManagement module does not work without git installed."
}

# Script-internal configuration object
$Script:GitManagement = @{
	Providers = @{ }
	BaseDirectory = $null
	Repositories = $null
	LastRepositoryScan = Get-Date
}

# Load everything
Get-ChildItem -Recurse $PSScriptRoot *.ps1 | ForEach-Object { . $_.FullName }

# Default providers
Add-Provider Azure 'https://(?:\w+@)?dev.azure.com/(?<Organization>\w+)/(?<Project>\w+)/_git/(?<Repository>[\w-_]+)' Organization, Project, Repository
Add-Provider GitHub 'https://github\.com/(?<UserOrOrganization>\w+)/(?<Repository>[\w-_]+)\.git' UserOrOrganization, Repository
Add-Provider Bitbucket 'https://(?:\w+@)?bitbucket.org/(?<User>\w+)/(?<Repository>[\w-_]+)\.git' User, Repository
