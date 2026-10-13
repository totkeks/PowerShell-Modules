@{
    RootModule        = 'totkeks.GitManagement.psm1'
    ModuleVersion     = '2.0.0'
    GUID              = 'e2d394da-db1d-4ad6-b98c-104379eb299a'
    Author            = 'Norman Dankert'
    Copyright         = '(c) Norman Dankert. All rights reserved.'
    Description       = 'PowerShell module with commands to manage git hosting providers, to handle repositories and to organize them in a local project structure.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    FormatsToProcess  = @('GitRepository.Format.ps1xml')
    FunctionsToExport = @()
    CmdletsToExport   = @(
        'Get-Provider'
        'Add-Provider'
        'Remove-Provider'
        'Get-BaseDirectory'
        'Set-BaseDirectory'
        'Get-Repository'
        'Enter-Repository'
        'New-Repository'
        'Install-Repository'
        'Remove-Branch'
    )
    AliasesToExport   = @('Clone-Repository')
    DefaultCommandPrefix = 'Git'
    PrivateData       = @{
        PSData = @{
            Tags       = @('Git', 'Management', 'GitHub', 'AzureDevOps', 'Bitbucket')
            LicenseUri = 'https://github.com/totkeks/PowerShell-Modules/blob/main/LICENSE'
            ProjectUri = 'https://github.com/totkeks/PowerShell-Modules'
        }
    }
}
