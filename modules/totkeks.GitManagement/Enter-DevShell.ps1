$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'Build.ps1')

$manifestPath = Join-Path $PSScriptRoot 'out\totkeks.GitManagement\totkeks.GitManagement.psd1'
Import-Module -Name $manifestPath -Force -ErrorAction Stop

Set-Location -LiteralPath $PSScriptRoot
Write-Host "Module loaded: $manifestPath"

Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-GitBaseDirectory E:/
