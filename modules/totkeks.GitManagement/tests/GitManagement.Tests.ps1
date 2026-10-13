BeforeAll {
    $script:modulePath = (Resolve-Path (Join-Path $PSScriptRoot '..\out\totkeks.GitManagement\totkeks.GitManagement.psd1')).Path
    $script:baseDirectory = Join-Path $TestDrive 'repositories'
    New-Item -ItemType Directory -Path $script:baseDirectory -Force | Out-Null
    Import-Module -Name $script:modulePath -Force
    Set-GitBaseDirectory -Path $script:baseDirectory
}

Describe 'totkeks.GitManagement command surface' {
    It 'exports the legacy Git-prefixed commands and clone alias' {
        $commands = (Get-Command -Module totkeks.GitManagement).Name
        $commands | Should -Contain 'Get-GitProvider'
        $commands | Should -Contain 'Add-GitProvider'
        $commands | Should -Contain 'Remove-GitProvider'
        $commands | Should -Contain 'Get-GitBaseDirectory'
        $commands | Should -Contain 'Set-GitBaseDirectory'
        $commands | Should -Contain 'Get-GitRepository'
        $commands | Should -Contain 'Enter-GitRepository'
        $commands | Should -Contain 'New-GitRepository'
        $commands | Should -Contain 'Install-GitRepository'
        $commands | Should -Contain 'Remove-GitBranch'
        $commands | Should -Contain 'Clone-GitRepository'
    }

    It 'initializes the built-in providers and rejects invalid provider patterns' {
        (Get-GitProvider).Name | Should -Contain 'Azure'
        (Get-GitProvider).Name | Should -Contain 'GitHub'
        (Get-GitProvider).Name | Should -Contain 'Bitbucket'

        { Add-GitProvider -Name Invalid -UrlPattern 'https://example.invalid/(?<Name>.*)' -DirectoryHierarchy Repository -ErrorAction Stop } |
            Should -Throw '*must contain the named capturing group*'
        { Add-GitProvider -Name '../escape' -UrlPattern 'https://example.invalid/(?<Repository>.*)' -ErrorAction Stop } |
            Should -Throw '*simple directory names*'
        { Get-GitRepository -Provider Missing -ErrorAction Stop } | Should -Throw '*does not exist*'
    }

    It 'completes the name of a provider when removing it' {
        $inputText = 'Get-GitProvider -Name G'
        $matches = [System.Management.Automation.CommandCompletion]::CompleteInput(
            $inputText,
            $inputText.Length,
            $null
        ).CompletionMatches.CompletionText
        $matches | Should -Contain 'GitHub'

        $inputText = 'Remove-GitProvider -Name G'
        $matches = [System.Management.Automation.CommandCompletion]::CompleteInput(
            $inputText,
            $inputText.Length,
            $null
        ).CompletionMatches.CompletionText
        $matches | Should -Contain 'GitHub'
    }
}

Describe 'repository operations and argument completion' {
    BeforeAll {
        New-GitRepository GitHub -UserOrOrganization totkeks -Repository migration-smoke | Out-Null
        $script:repository = Get-GitRepository -Exact migration-smoke
    }

    It 'creates and discovers repositories with provider hierarchy properties' {
        $script:repository.Provider | Should -Be 'GitHub'
        $script:repository.Properties['UserOrOrganization'] | Should -Be 'totkeks'
        $script:repository.Properties['Repository'] | Should -Be 'migration-smoke'
        (Get-GitRepository -Name migration).Path | Should -Be $script:repository.Path
        (Get-GitRepository -Name 'migration-*').Path | Should -Be $script:repository.Path
    }

    It 'completes configured providers and existing repository names' {
        $providerInput = 'Get-GitRepository -Provider G'
        $providerMatches = [System.Management.Automation.CommandCompletion]::CompleteInput(
            $providerInput,
            $providerInput.Length,
            $null
        ).CompletionMatches.CompletionText
        $providerMatches | Should -Contain 'GitHub'

        $repositoryInput = 'Enter-GitRepository migration'
        $repositoryMatches = [System.Management.Automation.CommandCompletion]::CompleteInput(
            $repositoryInput,
            $repositoryInput.Length,
            $null
        ).CompletionMatches.ListItemText
        $repositoryMatches | Should -Contain 'migration-smoke'
    }

    It 'completes duplicate repository names with provider-specific hierarchy selectors' {
        New-GitRepository GitHub -UserOrOrganization "alice's org" -Repository completion-collision | Out-Null
        New-GitRepository Bitbucket -User bob -Repository completion-collision | Out-Null
        New-GitRepository Azure -Organization example -Project project -Repository completion-collision | Out-Null

        $inputText = 'Enter-GitRepository completion-collision'
        $matches = [System.Management.Automation.CommandCompletion]::CompleteInput(
            $inputText,
            $inputText.Length,
            $null
        ).CompletionMatches | Where-Object ToolTip -Like 'User: *; Provider: *'

        @($matches).Count | Should -Be 2
        $githubMatch = $matches | Where-Object ToolTip -EQ "User: alice's org; Provider: GitHub"
        $bitbucketMatch = $matches | Where-Object ToolTip -EQ 'User: bob; Provider: Bitbucket'

        $allMatches = [System.Management.Automation.CommandCompletion]::CompleteInput(
            $inputText,
            $inputText.Length,
            $null
        ).CompletionMatches | Where-Object CompletionText -Like "'completion-collision' -Provider *"
        @($allMatches).Count | Should -Be 3
        $githubMatch.CompletionText | Should -Be "'completion-collision' -Provider 'GitHub' -UserOrOrganization 'alice''s org'"
        $githubMatch.ListItemText | Should -Be 'completion-collision'
        $bitbucketMatch.CompletionText | Should -Be "'completion-collision' -Provider 'Bitbucket' -User 'bob'"
        $bitbucketMatch.ListItemText | Should -Be 'completion-collision'
        $allMatches.ToolTip | Should -Contain 'User: alice''s org; Provider: GitHub'
        $allMatches.ToolTip | Should -Contain 'User: bob; Provider: Bitbucket'
        $allMatches.ToolTip | Should -Contain 'Organization: example; Project: project; Provider: Azure'

        $azureMatch = $allMatches | Where-Object ToolTip -EQ 'Organization: example; Project: project; Provider: Azure'
        $azureMatch.CompletionText | Should -Be "'completion-collision' -Provider 'Azure' -Organization 'example' -Project 'project'"
        $azureMatch.ListItemText | Should -Be 'completion-collision'

        $boundProviderInput = 'Enter-GitRepository -Provider GitHub completion-collision'
        $boundProviderMatches = [System.Management.Automation.CommandCompletion]::CompleteInput(
            $boundProviderInput,
            $boundProviderInput.Length,
            $null
        ).CompletionMatches
        @($boundProviderMatches).Count | Should -Be 1
        $boundProviderMatches[0].CompletionText | Should -Be "'completion-collision' -UserOrOrganization 'alice''s org'"

        $githubRepositoryPath = (Get-GitRepository -Name completion-collision -Provider GitHub -Exact).Path
        Push-Location
        try {
            Invoke-Expression "Enter-GitRepository $($githubMatch.CompletionText)"
            (Get-Location).Path | Should -Be $githubRepositoryPath
        }
        finally {
            Pop-Location
        }

        $azureRepositoryPath = (Get-GitRepository -Name completion-collision -Provider Azure -Exact).Path
        Push-Location
        try {
            Invoke-Expression "Enter-GitRepository $($azureMatch.CompletionText)"
            (Get-Location).Path | Should -Be $azureRepositoryPath
        }
        finally {
            Pop-Location
        }
    }

    It 'uses provider hierarchy dynamic parameters when creating a repository' {
        { New-GitRepository GitHub -UserOrOrganization owner -Repository } | Should -Throw
    }

    It 'changes location when entering a repository' {
        Push-Location
        try {
            Enter-GitRepository migration-smoke
            (Get-Location).Path | Should -Be $script:repository.Path
        }
        finally {
            Pop-Location
        }
    }
}

Describe 'branch operations' {
    BeforeAll {
        New-Item -ItemType Directory -Path $script:baseDirectory -Force | Out-Null
        New-GitRepository GitHub -UserOrOrganization totkeks -Repository branch-smoke | Out-Null
        $script:branchRepository = Get-GitRepository -Exact branch-smoke
    }

    It 'deletes a named local branch and honors WhatIf' {
        $repositoryPath = $script:branchRepository.Path
        git -C $repositoryPath config user.email 'gitmanagement-tests@example.invalid'
        git -C $repositoryPath config user.name 'GitManagement Tests'
        Set-Content -LiteralPath (Join-Path $repositoryPath 'test.txt') -Value 'branch test'
        git -C $repositoryPath add test.txt
        git -C $repositoryPath commit -m 'test branch operations' | Out-Null

        $defaultBranch = (git -C $repositoryPath branch --show-current).Trim()
        git -C $repositoryPath switch -c migration-test-branch | Out-Null
        git -C $repositoryPath switch $defaultBranch | Out-Null

        Push-Location $repositoryPath
        try {
            Remove-GitBranch migration-test-branch -WhatIf -Confirm:$false
            (git branch --list migration-test-branch).Trim() | Should -Be 'migration-test-branch'

            Remove-GitBranch migration-test-branch -Confirm:$false
            @(git branch --list migration-test-branch).Count | Should -Be 0
        }
        finally {
            Pop-Location
        }
    }

    It 'deletes remote branches and cleans up gone upstream branches' {
        $repositoryPath = $script:branchRepository.Path
        $remotePath = Join-Path $TestDrive 'branch-remote.git'
        git init --bare $remotePath | Out-Null
        git -C $repositoryPath remote add origin $remotePath
        $defaultBranch = (git -C $repositoryPath branch --show-current).Trim()
        git -C $repositoryPath switch -c gone-upstream-test | Out-Null
        git -C $repositoryPath push -u origin gone-upstream-test | Out-Null
        git -C $repositoryPath switch $defaultBranch | Out-Null

        Push-Location $repositoryPath
        try {
            Remove-GitBranch origin/gone-upstream-test -Remote -Confirm:$false
            @(git --git-dir $remotePath for-each-ref '--format=%(refname)' refs/heads).Count | Should -Be 0

            Remove-GitBranch -Gone -Confirm:$false
            @(git branch --list gone-upstream-test).Count | Should -Be 0
        }
        finally {
            Pop-Location
        }
    }
}

Describe 'repository installation' {
    BeforeAll {
        New-Item -ItemType Directory -Path $script:baseDirectory -Force | Out-Null
        Set-GitBaseDirectory -Path $script:baseDirectory

        $script:sourceWorktree = Join-Path $TestDrive 'clone-source-worktree'
        $script:bareSource = Join-Path $TestDrive 'clone-source.git'
        New-Item -ItemType Directory -Path $script:sourceWorktree -Force | Out-Null
        git -C $script:sourceWorktree init | Out-Null
        git -C $script:sourceWorktree config user.email 'gitmanagement-tests@example.invalid'
        git -C $script:sourceWorktree config user.name 'GitManagement Tests'
        Set-Content -LiteralPath (Join-Path $script:sourceWorktree 'source.txt') -Value 'clone source'
        git -C $script:sourceWorktree add source.txt
        git -C $script:sourceWorktree commit -m 'create clone source' | Out-Null
        git clone --bare $script:sourceWorktree $script:bareSource | Out-Null

        Add-GitProvider -Name LocalTest -UrlPattern '[\\/](?<Repository>clone-source)\.git$' -DirectoryHierarchy Repository
    }

    It 'clones through the alias, resolves provider paths, and replaces targets with Force' {
        $targetPath = Join-Path $script:baseDirectory 'LocalTest\clone-source'
        Push-Location
        try {
            Clone-GitRepository $script:bareSource -Confirm:$false | Out-Null
            (Test-Path -LiteralPath (Join-Path $targetPath 'source.txt')) | Should -BeTrue

            Set-Content -LiteralPath (Join-Path $targetPath 'stale.txt') -Value 'remove me'
            Clone-GitRepository $script:bareSource -Force -Confirm:$false | Out-Null
            (Test-Path -LiteralPath (Join-Path $targetPath 'stale.txt')) | Should -BeFalse
            (Test-Path -LiteralPath (Join-Path $targetPath 'source.txt')) | Should -BeTrue
        }
        finally {
            Pop-Location
        }
    }
}

Describe 'runtime configuration isolation' {
    It 'does not share provider mutations with a separate runspace' {
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $worker = [powershell]::Create()
        try {
            $runspace.Open()
            $worker.Runspace = $runspace
            [void]$worker.AddScript({
                param($Path)
                Import-Module -Name $Path -Force
                Add-GitProvider -Name Isolated -UrlPattern 'https://isolated.invalid/(?<Repository>[^/]+)' -DirectoryHierarchy Repository
                (Get-GitProvider -Name Isolated).Name
            }).AddArgument($script:modulePath)

            $worker.Invoke() | Should -Contain 'Isolated'
            $worker.HadErrors | Should -BeFalse
            { Get-GitProvider -Name Isolated -ErrorAction Stop } | Should -Throw '*does not exist*'
        }
        finally {
            $worker.Dispose()
            $runspace.Dispose()
        }
    }
}

AfterAll {
    Remove-Module -Name totkeks.GitManagement -Force -ErrorAction SilentlyContinue
}
