function Get-Branch {
	[CmdletBinding()]
	Param (
		[Parameter()]
		[switch] $Remote
	)

	if (-not (Test-Repository)) {
		Write-Error "Command needs to be run inside a git repository. Aborting."
	}

	git for-each-ref --format '%(refname:short)' $(if ($Remote) { "refs/remotes" } else { "refs/heads" })
}
