# totkeks.GitManagement

A C# binary PowerShell module for managing Git hosting providers, local repositories, and branches. It targets PowerShell 7.4+ and .NET 8.

## Build and import

```powershell
.\Build.ps1
Import-Module .\totkeks.GitManagement.psd1 -Force
```

Git must be installed and available on `PATH`. The build script places intermediate files under `build`, copies the assembly into this directory for development imports, and creates a clean installable module under `out\totkeks.GitManagement`.

## Commands

The manifest applies the legacy `Git` command prefix:

| Command | Purpose |
| --- | --- |
| `Get-GitProvider` | List configured providers or retrieve one by name. |
| `Add-GitProvider` / `Remove-GitProvider` | Configure URL patterns and repository directory hierarchies. |
| `Get-GitBaseDirectory` / `Set-GitBaseDirectory` | Read or set the existing root folder used to organize clones. |
| `Get-GitRepository` | Discover local repositories; filter by name, exact name, provider, or refresh the cache. |
| `Enter-GitRepository` | Change location to a repository, prompting when names are ambiguous. |
| `New-GitRepository` | Initialize a repository using dynamic hierarchy parameters for the selected provider. |
| `Install-GitRepository` | Clone a provider URL into the configured hierarchy; `-Force` replaces an existing target. |
| `Remove-GitBranch` | Delete a named local or remote branch, or clean up gone-upstream branches with `-Gone`. |
| `Clone-GitRepository` | Alias for `Install-GitRepository`. |

Azure, GitHub, and Bitbucket are configured when the module is imported. For example:

```powershell
Set-GitBaseDirectory C:\Projects
Get-GitProvider
New-GitRepository GitHub -UserOrOrganization totkeks -Repository PowerShell-Modules
Get-GitRepository -Provider GitHub
Enter-GitRepository PowerShell-Modules
```

`New-GitRepository` exposes mandatory dynamic parameters corresponding to the selected provider's hierarchy. `Add-GitProvider` requires a valid regex with a named `Repository` capture and a hierarchy that includes `Repository`.

Provider and repository-name arguments have tab completion. Completion uses the current module runtime configuration and repository cache; it does not maintain a separate stale list. Invalid provider values and missing repository paths are reported as PowerShell errors.

Each imported module instance owns its provider settings, base directory, and repository cache. Independent PowerShell runspaces do not share these mutable settings. Repository discovery refreshes automatically after five minutes and can be forced with `Get-GitRepository -Refresh`.

Branch deletion and replacement operations support PowerShell `-WhatIf` and `-Confirm` where applicable. Named local branch deletion uses Git's safe `-d` behavior; gone-upstream cleanup uses `-D` after pruning and confirmation.

## Development

Run the regression tests from the repository root:

```powershell
Invoke-Pester .\modules\totkeks.GitManagement\tests\GitManagement.Tests.ps1 -CI
```

Run `.\Enter-DevShell.ps1` to build, import the module, and switch to the module directory in the current session. In VS Code, open the repository root and run **Tasks: Run Task** → **GitManagement: PowerShell dev shell** to open a dedicated integrated PowerShell terminal with the module loaded.
