function Set-DevDriveCache {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, HelpMessage = 'Path to the dev drive.')]
		[ValidateScript({ Test-Path $_ })]
		[string]$Path
	)

	Write-Verbose 'Configuring dev drive caches'

	$basePath = Join-Path $Path 'packages'
	New-Item -Path $basePath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

	#region JavaScript & TypeScript
	$npmPath = Join-Path $basePath 'npm'
	Write-Verbose "Setting npm cache to $npmPath"
	New-Item -Path $npmPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable('npm_config_cache', $npmPath, [EnvironmentVariableTarget]::User)

	$yarnPath = Join-Path $basePath 'yarn'
	Write-Verbose "Setting Yarn cache to $yarnPath"
	New-Item -Path $yarnPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable('YARN_CACHE_FOLDER', $yarnPath, [EnvironmentVariableTarget]::User)
	[Environment]::SetEnvironmentVariable('YARN_ENABLE_GLOBAL_CACHE', 'true', [EnvironmentVariableTarget]::User)
	#endregion

	#region .NET
	$nugetPath = Join-Path $basePath 'nuget'
	Write-Verbose "Setting NuGet cache to $nugetPath"
	New-Item -Path $nugetPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable('NUGET_PACKAGES', $nugetPath, [EnvironmentVariableTarget]::User)
	#endregion

	#region C & C++
	$vcpkgPath = Join-Path $basePath 'vcpkg'
	Write-Verbose "Setting Vcpkg cache to $vcpkgPath"
	New-Item -Path $vcpkgPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable('VCPKG_DEFAULT_BINARY_CACHE', $vcpkgPath, [EnvironmentVariableTarget]::User)
	#endregion

	#region Python
	$pipPath = Join-Path $basePath 'pip'
	Write-Verbose "Setting pip cache to $pipPath"
	New-Item -Path $pipPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable('PIP_CACHE_DIR', $pipPath, [EnvironmentVariableTarget]::User)

	$poetryPath = Join-Path $basePath 'poetry'
	Write-Verbose "Setting Poetry cache to $poetryPath"
	New-Item -Path $poetryPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable('POETRY_CACHE_DIR', $poetryPath, [EnvironmentVariableTarget]::User)

	$uvPath = Join-Path $basePath 'uv'
	Write-Verbose "Setting uv cache to $uvPath"
	New-Item -Path $uvPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable('UV_CACHE_DIR', $uvPath, [EnvironmentVariableTarget]::User)
	#endregion

	#region Rust
	$cargoPath = Join-Path $basePath 'cargo'
	Write-Verbose "Setting Cargo cache to $cargoPath"
	New-Item -Path $cargoPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable('CARGO_HOME', $cargoPath, [EnvironmentVariableTarget]::User)
	#endregion

	#region Java
	$mavenPath = Join-Path $basePath 'maven'
	Write-Verbose "Setting Maven cache to $mavenPath"
	New-Item -Path $mavenPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	[Environment]::SetEnvironmentVariable('MAVEN_OPTS', "-Dmaven.repo.local=$mavenPath", [EnvironmentVariableTarget]::User)
	#endregion
}
