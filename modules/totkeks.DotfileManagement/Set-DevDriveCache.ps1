function Set-DevDriveCache {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, HelpMessage = "Path to the dev drive.")]
		[ValidateScript({ Test-Path $_ })]
		[string]$Path
	)

	Write-Verbose "Configuring dev drive caches"

	$basePath = Join-Path $Path "packages"
	New-Item -Path $basePath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

	$npmPath = Join-Path $basePath "npm"
	Write-Verbose "Setting npm cache to $npmPath"
	New-Item -Path $npmPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable("npm_config_cache", $npmPath, [EnvironmentVariableTarget]::User)

	$nugetPath = Join-Path $basePath "nuget"
	Write-Verbose "Setting NuGet cache to $nugetPath"
	New-Item -Path $nugetPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable("NUGET_PACKAGES", $nugetPath, [EnvironmentVariableTarget]::User)

	$vcpkgPath = Join-Path $basePath "vcpkg"
	Write-Verbose "Setting Vcpkg cache to $vcpkgPath"
	New-Item -Path $vcpkgPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable("VCPKG_DEFAULT_BINARY_CACHE", $vcpkgPath, [EnvironmentVariableTarget]::User)

	$pipPath = Join-Path $basePath "pip"
	Write-Verbose "Setting pip cache to $pipPath"
	New-Item -Path $pipPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable("PIP_CACHE_DIR", $pipPath, [EnvironmentVariableTarget]::User)

	$cargoPath = Join-Path $basePath "cargo"
	Write-Verbose "Setting Cargo cache to $cargoPath"
	New-Item -Path $cargoPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable("CARGO_HOME", $cargoPath, [EnvironmentVariableTarget]::User)

	$mavenPath = Join-Path $basePath "maven"
	Write-Verbose "Setting Maven cache to $mavenPath"
	New-Item -Path $mavenPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable("MAVEN_OPTS", "-Dmaven.repo.local=$mavenPath", [EnvironmentVariableTarget]::User)
}
