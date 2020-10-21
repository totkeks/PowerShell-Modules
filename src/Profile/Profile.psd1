@{
    RootModule = 'Profile.psm1'
    ModuleVersion = '0.0.1'
    GUID = 'bcadff99-6045-4568-8f69-82be0b36879c'
    Author = 'Norman Dankert'
    Copyright = '(c) Norman Dankert. All rights reserved.'

    # FormatsToProcess = @()

    # NestedModules = @()

    FunctionsToExport = @(
        "Start-LoadingSequence"
        "Stop-LoadingSequence"
        "Write-Host"
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    PrivateData = @{
        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            # ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()
        }
    }

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = 'Profile'
}
