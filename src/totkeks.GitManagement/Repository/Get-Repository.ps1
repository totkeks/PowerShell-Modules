using module ..\Generators\ExistingProvidersGenerator.psm1

<#
.SYNOPSIS
	Gets the repositories available locally.

.EXAMPLE
	Get-Repository

	This will list all locally cloned repositories.

.EXAMPLE
	Get-Repository -Provider GitHub

	This will list all repositories cloned from GitHub.

.LINK
	New-Repository
	Enter-Repository
#>
function Get-Repository {
	param (
		[parameter(Position = 0, HelpMessage = "Name of the repository.")]
		[string] $Name,

		[ValidateScript({
				if ($_ -notin [ExistingProvidersGenerator]::new().GetValidValues()) { throw "Not a valid value: $_" }
				$true
			})]
		[ArgumentCompleter({
				param($command, $param, $wordToComplete)
				[ExistingProvidersGenerator]::new().GetValidValues() -like "$wordToComplete*"
			})]
		[string] $Provider,

		[parameter(HelpMessage = "Use exact match instead of wildcard match.")]
		[switch] $Exact,

		[parameter(HelpMessage = "Refresh the list of repositories.")]
		[switch] $Refresh
	)

	process {
		$repositories = Find-Repository -Refresh:$Refresh

		if ($Name) {
			$repositories = $repositories | Where-Object { if ($Exact) { $_.Properties.Repository -eq $Name } else { $_.Properties.Repository -like "*$Name*" } }

			if (!$repositories) {
				Write-Error "No repositories found matching name '$Name'."
				return
			}
		}

		if ($Provider) {
			$repositories = $repositories | Where-Object Provider -EQ $Provider
		}

		$repositories
	}
}
