function Remove-Branch {
	[CmdletBinding(DefaultParameterSetName = "ByName")]
	Param (
		[Parameter(Mandatory, Position = 0, ParameterSetName = "ByName")]
		[string] $Name,

		[Parameter(ParameterSetName = "ByName")]
		[switch] $Remote,

		[Parameter(Mandatory, ParameterSetName = "Gone")]
		[switch] $Gone
	)

	Begin {
		if (-not (Test-Repository)) {
			Write-Error "Command needs to be run inside a git repository. Aborting."
		}
	}

	Process {
		switch ($PSCmdlet.ParameterSetName) {
			"ByName" {
				throw "removal by name not yet supported"
			}

			"Gone" {
				git fetch --prune

				$branches = @(git for-each-ref --format "%(refname:short) %(upstream:track)" refs/heads) -match "\w+ \[gone\]$" -replace " \[gone\]$"

				if ($branches.Length -eq 0) {
					Write-Host "No gone branches found that need cleanup."
				}

				foreach ($branch in $branches) {
					if ($PSCmdlet.ShouldContinue("Are you sure you want to delete branch $branch?", "Delete branch")) {
						git branch -D $branch
					}
				}
			}
		}
	}
}
