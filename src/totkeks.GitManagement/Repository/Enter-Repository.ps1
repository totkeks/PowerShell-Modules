using module ..\Generators\ExistingRepositoriesGenerator.psm1

function Enter-Repository {
	<#
		.SYNOPSIS
			Enters the location of a git repository.

		.EXAMPLE
			Enter-Repository PowerShell-Modules

			This will set the current location to the 'PowerShell-Modules' repository.

		.LINK
			New-Repository
			Get-Repository
	#>
	[CmdletBinding()]
	Param(
		[parameter(Mandatory)]
		[ValidateScript({
				if ($_ -notin [ExistingRepositoriesGenerator]::new().GetValidValues()) { throw "Not a valid value: $_" }
				$true
		 })]
		[ArgumentCompleter({
				param($command, $param, $wordToComplete)
				[ExistingRepositoriesGenerator]::new().GetValidValues() -like "$wordToComplete*"
		 })]
		[string] $Name
	)

	Set-Location (Find-Repository | Where-Object { $_.Properties.Repository -eq $Name }).Path
}
