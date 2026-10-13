$ErrorActionPreference = 'Stop'

$gitCommand = Get-Command -Name git -ErrorAction SilentlyContinue
if ($null -eq $gitCommand) {
    throw "Unable to find 'git' in your PATH. GitManagement does not work without git installed."
}

$assemblyName = 'totkeks.GitManagement.dll'
$assemblyPath = Join-Path -Path $PSScriptRoot -ChildPath $assemblyName

if (-not (Test-Path $assemblyPath)) {
    throw "Assembly $assemblyName not found. Build the project first by running Build.ps1."
}

Import-Module -Name $assemblyPath -ErrorAction Stop
$script:GitManagementRuntime = [Totkeks.GitManagement.GitManagementRuntime]::CreateDefault()

Set-Alias -Name Clone-Repository -Value Install-Repository -Scope Script

$providerCompleter = {
    param($commandName, $parameterName, $wordToComplete)
    [Totkeks.GitManagement.GitManagementCompletion]::CompleteProviders($script:GitManagementRuntime, $wordToComplete)
}

$repositoryCompleter = {
    param($commandName, $parameterName, $wordToComplete)
    [Totkeks.GitManagement.GitManagementCompletion]::CompleteRepositories($script:GitManagementRuntime, $wordToComplete)
}

Register-ArgumentCompleter -CommandName 'Get-Repository', 'Get-GitRepository' -ParameterName Provider -ScriptBlock $providerCompleter
Register-ArgumentCompleter -CommandName 'Get-Provider', 'Get-GitProvider' -ParameterName Name -ScriptBlock $providerCompleter
Register-ArgumentCompleter -CommandName 'New-Repository', 'New-GitRepository' -ParameterName Provider -ScriptBlock $providerCompleter
Register-ArgumentCompleter -CommandName 'Remove-Provider', 'Remove-GitProvider' -ParameterName Name -ScriptBlock $providerCompleter
Register-ArgumentCompleter -CommandName 'Enter-Repository', 'Enter-GitRepository' -ParameterName Name -ScriptBlock $repositoryCompleter
