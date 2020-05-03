# PowerShell Modules

This repository contains a collection of PowerShell modules I created to help with daily and/or repeating tasks.
The different modules are described in the following sections.

## Git Management

The `GitManagement` module provides commands to manage git hosting providers, to handle repositories and to organize them in a local project structure.

### Git Hosting Providers

A git hosting provider, or short git provider, allows you to remotely store your git repository. By default there are three providers configured: [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/), [Bitbucket](https://bitbucket.org/) and [GitHub](https://github.com/).

Each provider is defined by its unique name, the url pattern for its repositories and a directory hierarchy for the local project structure. This information can be displayed using the `Get-GitProvider` command and looks like this:

```powershell
> Get-GitProvider

Name      UrlPattern                                                                                      DirectoryHierarchy
----      ----------                                                                                      ------------------
Azure     https://(?:\w+@)?dev.azure.com/(?<Organization>\w+)/(?<Project>\w+)/_git/(?<Repository>[\w-_]+) {Organization, Project, Repository}
Bitbucket https://(?:\w+@)?bitbucket.org/(?<User>\w+)/(?<Repository>[\w-_]+)\.git                         {User, Repository}
GitHub    https://github\.com/(?<UserOrOrganization>\w+)/(?<Repository>[\w-_]+)\.git                      {UserOrOrganization, Repository}
```

Adding your own hosting providers can be done using the `Add-GitProvider` command. Simply supply the three properties mentioned above.

Removing them again can be done with the `Remove-GitProvider` command. You can even remove the defaults this way, if you want to.

### Local Project Structure

The local project structure helps organizing all your cloned repositories. It is based on the directory hierarchy of each git provider.

This solves two issues. One is dealing with repositories with identical names in general, the other is dealing with forked repositories, which also happen to have identical names.

The base directory can be set using `Set-GitBaseDirectory`. Similarly `Get-GitBaseDirectory` returns the current base directory.

**Note:** You can't use any of the git management features without setting a base directory first.

### Git Repositories

Last but not least, the main functions to handle your git repositories.

Cloning a repository can be done with the `Get-GitRepository` command, which matches the provided repository url with the known providers and automatically clones the repository to the correct directory in the local project structure.
