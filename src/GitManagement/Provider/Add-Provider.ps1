function Add-Provider {
	<#
		.SYNOPSIS
			Adds an additional git hosting provider to the configuration.

		.EXAMPLE
			Add-Provider Azure 'https://(?:\w+@)?dev.azure.com/(?<Organization>\w+)/(?<Project>\w+)/_git/(?<Repository>[\w-_]+)' Organization, Project, Repository

			This will add the 'Azure' provider to the configuration.

		.LINK
			Get-Provider
			Remove-Provider
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript(
			{ (Get-Provider) -notcontains $_ },
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
