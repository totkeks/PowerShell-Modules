$Script:ImportModuleFunction = {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		$Name
	)

	$version = (Get-Module -ListAvailable $Name | Sort-Object -Descending Version -Top 1).Version

	Write-Host -NoNewline "Loading version $version of module $Name "
	Microsoft.PowerShell.Core\Import-Module $Name -Verbose 4>&1 | ForEach-Object { Write-Host -NoNewline -ContinueLine "." }
	Write-Host -ContinueLine " $($ProfileManagement.Checkmark)"
}
