$ErrorActionPreference = 'Stop'

$projectPath = Join-Path $PSScriptRoot 'src\totkeks.GitManagement.csproj'
$assemblyName = 'totkeks.GitManagement.dll'
$outputPath = Join-Path $PSScriptRoot "build\bin\Release\net8.0\$assemblyName"
$moduleAssemblyPath = Join-Path $PSScriptRoot $assemblyName
$moduleOutputPath = Join-Path $PSScriptRoot 'out\totkeks.GitManagement'

& dotnet build $projectPath --configuration Release
if ($LASTEXITCODE -ne 0) {
    throw "dotnet build failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "Build succeeded, but the assembly was not found at $outputPath."
}

Copy-Item -LiteralPath $outputPath -Destination $moduleAssemblyPath -Force

if (Test-Path -LiteralPath $moduleOutputPath) {
    Remove-Item -LiteralPath $moduleOutputPath -Recurse -Force
}

New-Item -ItemType Directory -Path $moduleOutputPath -Force | Out-Null

$moduleFiles = @(
    'totkeks.GitManagement.psd1'
    'totkeks.GitManagement.psm1'
    'GitRepository.Format.ps1xml'
)

foreach ($file in $moduleFiles) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination $moduleOutputPath
}

Copy-Item -LiteralPath $outputPath -Destination (Join-Path $moduleOutputPath $assemblyName)

Write-Host "Built development assembly: $moduleAssemblyPath"
Write-Host "Staged module: $moduleOutputPath"
