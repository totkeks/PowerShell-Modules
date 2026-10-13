$ErrorActionPreference = 'Stop'

$UserModulePath = $env:PSModulePath -split [IO.Path]::PathSeparator |
	Where-Object { $_ -and $_.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase) } |
	Select-Object -First 1

if (-not $UserModulePath) {
	throw "Unable to find a user module directory in PSModulePath for $HOME."
}

$Modules = @(
	'totkeks.GitManagement'
)

foreach ($module in $Modules) {
	$modulePath = Join-Path (Join-Path $PSScriptRoot 'modules') $module
	$buildScript = Join-Path $modulePath 'Build.ps1'

	if (Test-Path -LiteralPath $buildScript -PathType Leaf) {
		Write-Output "Building module $module"
		& $buildScript
	}

	$stagedModulePath = Join-Path $modulePath "out\$module"
	$sourcePath = if (Test-Path -LiteralPath $stagedModulePath -PathType Container) {
		$stagedModulePath
	}
	else {
		$modulePath
	}

	$manifestPath = Join-Path $sourcePath "$module.psd1"
	if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
		throw "Module manifest not found: $manifestPath"
	}

	$targetPath = Join-Path $UserModulePath $module

	if (Test-Path -LiteralPath $targetPath) {
		Write-Output "Removing existing module $module from $targetPath"
		Remove-Item -LiteralPath $targetPath -Recurse -Force
	}

	Write-Output "Installing module $module from $sourcePath to $targetPath"
	New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
	Get-ChildItem -LiteralPath $sourcePath -Force |
		Copy-Item -Destination $targetPath -Recurse -Force
}
