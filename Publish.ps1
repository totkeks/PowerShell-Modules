$ErrorActionPreference = 'Stop'

$modulesPath = Join-Path $PSScriptRoot 'modules'

foreach ($moduleDirectory in Get-ChildItem -LiteralPath $modulesPath -Directory) {
	$moduleName = $moduleDirectory.Name
	$modulePath = $moduleDirectory.FullName
	$buildScript = Join-Path $modulePath 'Build.ps1'

	if (Test-Path -LiteralPath $buildScript -PathType Leaf) {
		Write-Host "Building $moduleName"
		& $buildScript
	}

	$stagedModulePath = Join-Path $modulePath "out\$moduleName"
	$publishPath = if (Test-Path -LiteralPath $stagedModulePath -PathType Container) {
		$stagedModulePath
	}
	else {
		$modulePath
	}

	$manifestPath = Join-Path $publishPath "$moduleName.psd1"
	if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
		throw "Module manifest not found: $manifestPath"
	}

	$nextVersion = (Import-PowerShellDataFile -LiteralPath $manifestPath).ModuleVersion
	$latestVersion = (Find-PSResource -Name $moduleName -ErrorAction SilentlyContinue).Version

	if ($latestVersion -and ([version]$latestVersion -ge [version]$nextVersion)) {
		Write-Host "$moduleName is up to date, skipping publish"
		continue
	}

	Write-Host "Publishing $nextVersion of $moduleName from $publishPath"
	Publish-PSResource -Path $publishPath -ApiKey $env:NUGET_KEY
}
