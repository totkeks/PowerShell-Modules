$ErrorActionPreference = 'Stop'

$projectPath = Join-Path $PSScriptRoot 'src\totkeks.GitManagement.csproj'
$assemblyName = 'totkeks.GitManagement.dll'
$outputPath = Join-Path $PSScriptRoot "build\bin\Release\net8.0\$assemblyName"
$moduleOutputPath = Join-Path $PSScriptRoot 'out\totkeks.GitManagement'

& dotnet build $projectPath --configuration Release
if ($LASTEXITCODE -ne 0) {
    throw "dotnet build failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "Build succeeded, but the assembly was not found at $outputPath."
}

if (Test-Path -LiteralPath $moduleOutputPath) {
    Remove-Item -LiteralPath $moduleOutputPath -Recurse -Force
}

New-Item -ItemType Directory -Path $moduleOutputPath -Force | Out-Null

$moduleFiles = @(
    (Join-Path $PSScriptRoot 'totkeks.GitManagement.psd1')
    (Join-Path $PSScriptRoot 'totkeks.GitManagement.psm1')
    (Join-Path $PSScriptRoot 'GitRepository.Format.ps1xml')
    $outputPath
)

foreach ($file in $moduleFiles) {
    Copy-Item -LiteralPath $file -Destination $moduleOutputPath
}

Write-Host "Staged module: $moduleOutputPath"
