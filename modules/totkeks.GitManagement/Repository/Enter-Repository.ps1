using module ..\Generators\ExistingRepositoriesGenerator.psm1

function Enter-Repository {
	<#
		.SYNOPSIS
			Enters the location of a git repository.

		.EXAMPLE
			Enter-Repository PowerShell-Modules

			This will set the current location to the 'PowerShell-Modules' repository.

		.LINK
			Get-Repository
			Install-Repository
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

	$repositories = (Get-Repository -Exact $Name)

	if ($repositories.Count -gt 1) {
		$title = "Repository Selection"
		$message = "Found multiple repositories matching the same name. Please select one:"
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($repositories | ForEach-Object { $counter = 1 } {
				$distinguishableName = "&$counter. $($_.Properties[-2]) ($($_.Properties[-1]))"
				$counter++
				New-Object System.Management.Automation.Host.ChoiceDescription $distinguishableName
			})

		$selection = $Host.UI.PromptForChoice($title, $message, $options, 0)

		$repository = $repositories[$selection]
	}
	else {
		$repository = $repositories[0]
	}

	Set-Location $repository.Path
}
