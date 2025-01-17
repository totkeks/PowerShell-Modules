Get-ChildItem -Directory src | ForEach-Object {
	$moduleName = $_.Name
	$latestVersion = (Find-PSResource $moduleName).Version
	$nextVersion = (Import-PowerShellDataFile (Join-Path $_ "$moduleName.psd1")).ModuleVersion

	if ($latestVersion -ge $nextVersion) {
		Write-Host "$moduleName is up to date, skipping publish"
		return
	}

	Write-Host "Publishing $nextVersion of $moduleName"
	Publish-PSResource -Path $_ -ApiKey $env:NUGET_KEY
}
