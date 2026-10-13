using System.Collections;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Host;

namespace Totkeks.GitManagement;

internal static class CmdletUtilities
{
    internal static GitManagementRuntime GetRuntime(PSCmdlet cmdlet)
    {
        var module = cmdlet.MyInvocation.MyCommand.Module;
        var runtime = module?.SessionState?.PSVariable.GetValue("GitManagementRuntime") as GitManagementRuntime;
        return runtime ?? throw new InvalidOperationException($"The GitManagement runtime configuration was not initialized for module '{module?.Name}'.");
    }

    internal static void WriteFailure(PSCmdlet cmdlet, Exception exception, string errorId, ErrorCategory category, object? target = null)
    {
        cmdlet.WriteError(new ErrorRecord(exception, errorId, category, target));
    }

    internal static bool TryRunGit(PSCmdlet cmdlet, IReadOnlyList<string> arguments, string? workingDirectory, out GitProcessResult result)
    {
        try
        {
            result = GitProcess.Run(arguments, workingDirectory);
        }
        catch (Exception exception) when (exception is InvalidOperationException or System.ComponentModel.Win32Exception or DirectoryNotFoundException)
        {
            result = new GitProcessResult(-1, string.Empty, exception.Message);
        }

        if (result.ExitCode == 0)
        {
            return true;
        }

        var argumentText = string.Join(' ', arguments.Select(argument => $"'{argument}'"));
        var message = string.IsNullOrWhiteSpace(result.StandardError)
            ? $"git {argumentText} failed with exit code {result.ExitCode}."
            : result.StandardError.Trim();
        WriteFailure(cmdlet, new InvalidOperationException(message), "GitCommandFailed", ErrorCategory.InvalidResult, result);
        return false;
    }

    internal static void WriteGitOutput(PSCmdlet cmdlet, GitProcessResult result)
    {
        foreach (var line in result.StandardOutput.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries))
        {
            cmdlet.WriteObject(line);
        }
    }

    internal static bool IsRepository(PSCmdlet cmdlet, string path)
    {
        try
        {
            var result = GitProcess.Run(["rev-parse", "--is-inside-work-tree"], path);
            return result.ExitCode == 0 && string.Equals(result.StandardOutput.Trim(), "true", StringComparison.OrdinalIgnoreCase);
        }
        catch (Exception exception) when (exception is InvalidOperationException or System.ComponentModel.Win32Exception or DirectoryNotFoundException)
        {
            return false;
        }
    }

    internal static string CurrentPath(PSCmdlet cmdlet) => cmdlet.SessionState.Path.CurrentLocation.Path;

    internal static bool IsWithinDirectory(string path, string directory)
    {
        var relativePath = Path.GetRelativePath(directory, path);
        if (relativePath == ".")
        {
            return true;
        }

        if (Path.IsPathRooted(relativePath))
        {
            return false;
        }

        var firstSegment = relativePath.Split([Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar], StringSplitOptions.RemoveEmptyEntries).FirstOrDefault();
        return firstSegment is not null && firstSegment != "..";
    }

    internal static void DeleteFileSystemEntry(string path)
    {
        var attributes = File.GetAttributes(path);
        if ((attributes & FileAttributes.ReparsePoint) != 0)
        {
            if ((attributes & FileAttributes.Directory) != 0)
            {
                Directory.Delete(path);
            }
            else
            {
                File.Delete(path);
            }

            return;
        }

        if ((attributes & FileAttributes.Directory) == 0)
        {
            File.SetAttributes(path, FileAttributes.Normal);
            File.Delete(path);
            return;
        }

        foreach (var child in Directory.EnumerateFileSystemEntries(path))
        {
            DeleteFileSystemEntry(child);
        }

        File.SetAttributes(path, FileAttributes.Normal);
        Directory.Delete(path);
    }
}

[Cmdlet(VerbsCommon.Get, "Provider")]
[OutputType(typeof(PSObject))]
public sealed class GetProviderCommand : PSCmdlet
{
    [Parameter(Position = 0)]
    public string? Name { get; set; }

    protected override void ProcessRecord()
    {
        var runtime = CmdletUtilities.GetRuntime(this);
        if (!string.IsNullOrEmpty(Name))
        {
            var provider = runtime.FindProvider(Name);
            if (provider is null)
            {
                CmdletUtilities.WriteFailure(this, new ArgumentException($"The provider '{Name}' does not exist."), "ProviderNotFound", ErrorCategory.ObjectNotFound, Name);
                return;
            }

            WriteObject(provider.ToPowerShellObject());
            return;
        }

        foreach (var provider in runtime.GetProviders())
        {
            WriteObject(provider.ToPowerShellObject());
        }
    }
}

[Cmdlet(VerbsCommon.Add, "Provider")]
[OutputType(typeof(void))]
public sealed class AddProviderCommand : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0)]
    public string Name { get; set; } = string.Empty;

    [Parameter(Mandatory = true, Position = 1)]
    public string UrlPattern { get; set; } = string.Empty;

    [Parameter(Position = 2)]
    public string[] DirectoryHierarchy { get; set; } = ["Repository"];

    protected override void ProcessRecord()
    {
        try
        {
            CmdletUtilities.GetRuntime(this).AddProvider(Name, UrlPattern, DirectoryHierarchy);
        }
        catch (Exception exception) when (exception is ArgumentException or InvalidOperationException)
        {
            CmdletUtilities.WriteFailure(this, exception, "InvalidProvider", ErrorCategory.InvalidArgument, Name);
        }
    }
}

[Cmdlet(VerbsCommon.Remove, "Provider", SupportsShouldProcess = true, ConfirmImpact = ConfirmImpact.Medium)]
[OutputType(typeof(void))]
public sealed class RemoveProviderCommand : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0)]
    public string Name { get; set; } = string.Empty;

    protected override void ProcessRecord()
    {
        var runtime = CmdletUtilities.GetRuntime(this);
        if (runtime.FindProvider(Name) is null)
        {
            CmdletUtilities.WriteFailure(this, new ArgumentException($"The provider '{Name}' does not exist."), "ProviderNotFound", ErrorCategory.ObjectNotFound, Name);
            return;
        }

        if (ShouldProcess(Name, "Remove provider"))
        {
            runtime.RemoveProvider(Name);
        }
    }
}

[Cmdlet(VerbsCommon.Get, "BaseDirectory")]
[OutputType(typeof(string))]
public sealed class GetBaseDirectoryCommand : PSCmdlet
{
    protected override void ProcessRecord()
    {
        try
        {
            WriteObject(CmdletUtilities.GetRuntime(this).GetRequiredBaseDirectory());
        }
        catch (InvalidOperationException exception)
        {
            CmdletUtilities.WriteFailure(this, exception, "BaseDirectoryNotSet", ErrorCategory.InvalidOperation);
        }
    }
}

[Cmdlet(VerbsCommon.Set, "BaseDirectory")]
[OutputType(typeof(void))]
public sealed class SetBaseDirectoryCommand : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0)]
    public string Path { get; set; } = string.Empty;

    protected override void ProcessRecord()
    {
        try
        {
            CmdletUtilities.GetRuntime(this).SetBaseDirectory(Path);
        }
        catch (Exception exception) when (exception is ArgumentException or DirectoryNotFoundException or PathTooLongException)
        {
            CmdletUtilities.WriteFailure(this, exception, "InvalidBaseDirectory", ErrorCategory.InvalidArgument, Path);
        }
    }
}

[Cmdlet(VerbsCommon.Get, "Repository")]
[OutputType(typeof(PSObject))]
public sealed class GetRepositoryCommand : PSCmdlet
{
    [Parameter(Position = 0)]
    public string? Name { get; set; }

    [Parameter]
    public string? Provider { get; set; }

    [Parameter]
    public SwitchParameter Exact { get; set; }

    [Parameter]
    public SwitchParameter Refresh { get; set; }

    protected override void ProcessRecord()
    {
        var runtime = CmdletUtilities.GetRuntime(this);
        if (!string.IsNullOrEmpty(Provider) && runtime.FindProvider(Provider) is null)
        {
            CmdletUtilities.WriteFailure(this, new ArgumentException($"The provider '{Provider}' does not exist."), "ProviderNotFound", ErrorCategory.ObjectNotFound, Provider);
            return;
        }

        IReadOnlyList<GitRepository> repositories;
        try
        {
            repositories = runtime.GetRepositories(Refresh);
        }
        catch (Exception exception) when (exception is InvalidOperationException or IOException or UnauthorizedAccessException)
        {
            CmdletUtilities.WriteFailure(this, exception, "RepositoryScanFailed", ErrorCategory.ReadError);
            return;
        }

        if (!string.IsNullOrEmpty(Name))
        {
            WildcardPattern? namePattern = null;
            if (!Exact)
            {
                try
                {
                    namePattern = new WildcardPattern($"*{Name}*", WildcardOptions.IgnoreCase);
                }
                catch (ArgumentException exception)
                {
                    CmdletUtilities.WriteFailure(this, exception, "InvalidRepositoryNamePattern", ErrorCategory.InvalidArgument, Name);
                    return;
                }
            }

            repositories = repositories.Where(repository =>
            {
                var repositoryName = repository.Properties["Repository"]?.ToString() ?? string.Empty;
                return Exact
                    ? string.Equals(repositoryName, Name, StringComparison.OrdinalIgnoreCase)
                    : namePattern!.IsMatch(repositoryName);
            }).ToArray();

            if (repositories.Count == 0)
            {
                CmdletUtilities.WriteFailure(this, new ItemNotFoundException($"No repositories found matching name '{Name}'."), "RepositoryNotFound", ErrorCategory.ObjectNotFound, Name);
                return;
            }
        }

        if (!string.IsNullOrEmpty(Provider))
        {
            repositories = repositories.Where(repository => string.Equals(repository.Provider, Provider, StringComparison.OrdinalIgnoreCase)).ToArray();
        }

        foreach (var repository in repositories)
        {
            WriteObject(repository.ToPowerShellObject());
        }
    }
}

[Cmdlet(VerbsCommon.Enter, "Repository")]
[OutputType(typeof(void))]
public sealed class EnterRepositoryCommand : PSCmdlet, IDynamicParameters
{
    [Parameter(Mandatory = true, Position = 0)]
    public string Name { get; set; } = string.Empty;

    [Parameter]
    public string? Provider { get; set; }

    public object GetDynamicParameters()
    {
        var providerName = MyInvocation.BoundParameters.TryGetValue(nameof(Provider), out var boundProvider)
            ? boundProvider?.ToString()
            : Provider;
        var provider = string.IsNullOrWhiteSpace(providerName)
            ? null
            : CmdletUtilities.GetRuntime(this).FindProvider(providerName);

        var parameters = new RuntimeDefinedParameterDictionary();
        if (provider is null)
        {
            return parameters;
        }

        foreach (var parameterName in provider.DirectoryHierarchy.Where(parameter =>
                     !parameter.Equals("Repository", StringComparison.OrdinalIgnoreCase) &&
                     !parameter.Equals(nameof(Name), StringComparison.OrdinalIgnoreCase) &&
                     !parameter.Equals(nameof(Provider), StringComparison.OrdinalIgnoreCase)))
        {
            parameters.Add(parameterName, new RuntimeDefinedParameter(
                parameterName,
                typeof(string),
                new Collection<Attribute> { new ParameterAttribute() }));
        }

        return parameters;
    }

    protected override void ProcessRecord()
    {
        var runtime = CmdletUtilities.GetRuntime(this);
        var provider = string.IsNullOrWhiteSpace(Provider) ? null : runtime.FindProvider(Provider);
        if (!string.IsNullOrWhiteSpace(Provider) && provider is null)
        {
            CmdletUtilities.WriteFailure(this, new ArgumentException($"The provider '{Provider}' does not exist."), "ProviderNotFound", ErrorCategory.ObjectNotFound, Provider);
            return;
        }

        IReadOnlyList<GitRepository> repositories;
        try
        {
            repositories = runtime.GetRepositories()
                .Where(repository =>
                    string.Equals(repository.Properties["Repository"]?.ToString(), Name, StringComparison.OrdinalIgnoreCase) &&
                    (provider is null || string.Equals(repository.Provider, provider.Name, StringComparison.OrdinalIgnoreCase)) &&
                    (provider is null || provider.DirectoryHierarchy
                        .Where(parameterName =>
                            !parameterName.Equals("Repository", StringComparison.OrdinalIgnoreCase) &&
                            !parameterName.Equals(nameof(Name), StringComparison.OrdinalIgnoreCase) &&
                            !parameterName.Equals(nameof(Provider), StringComparison.OrdinalIgnoreCase))
                        .All(parameterName =>
                            !MyInvocation.BoundParameters.TryGetValue(parameterName, out var value) ||
                            string.Equals(repository.Properties[parameterName]?.ToString(), value?.ToString(), StringComparison.OrdinalIgnoreCase))))
                .ToArray();
        }
        catch (Exception exception) when (exception is InvalidOperationException or IOException or UnauthorizedAccessException)
        {
            CmdletUtilities.WriteFailure(this, exception, "RepositoryScanFailed", ErrorCategory.ReadError);
            return;
        }

        if (repositories.Count == 0)
        {
            CmdletUtilities.WriteFailure(this, new ItemNotFoundException($"No repositories found matching name '{Name}'."), "RepositoryNotFound", ErrorCategory.ObjectNotFound, Name);
            return;
        }

        var repository = repositories[0];
        if (repositories.Count > 1)
        {
            var choices = new Collection<ChoiceDescription>(repositories.Select((item, index) =>
                new ChoiceDescription($"&{index + 1}. {item.Properties.Values.Cast<object>().ElementAtOrDefault(Math.Max(0, item.Properties.Count - 2))} ({item.Properties.Values.Cast<object>().LastOrDefault()})")).ToArray());
            var selection = Host.UI.PromptForChoice("Repository Selection", "Found multiple repositories with the same name. Please select one:", choices, 0);
            repository = repositories[selection];
        }

        SessionState.Path.SetLocation(repository.Path);
    }
}

[Cmdlet(VerbsCommon.New, "Repository")]
[OutputType(typeof(string))]
public sealed class NewRepositoryCommand : PSCmdlet, IDynamicParameters
{
    [Parameter(Mandatory = true, Position = 0)]
    public string Provider { get; set; } = string.Empty;

    public object GetDynamicParameters()
    {
        var providerName = MyInvocation.BoundParameters.TryGetValue(nameof(Provider), out var boundProvider)
            ? boundProvider?.ToString()
            : Provider;
        if (string.IsNullOrWhiteSpace(providerName))
        {
            return new RuntimeDefinedParameterDictionary();
        }

        var provider = CmdletUtilities.GetRuntime(this).FindProvider(providerName);
        if (provider is null)
        {
            return new RuntimeDefinedParameterDictionary();
        }

        var parameters = new RuntimeDefinedParameterDictionary();
        for (var index = 0; index < provider.DirectoryHierarchy.Length; index++)
        {
            var parameterAttribute = new ParameterAttribute { Mandatory = true, Position = index + 1 };
            var attributes = new Collection<Attribute> { parameterAttribute };
            parameters.Add(provider.DirectoryHierarchy[index], new RuntimeDefinedParameter(provider.DirectoryHierarchy[index], typeof(string), attributes));
        }

        return parameters;
    }

    protected override void ProcessRecord()
    {
        var runtime = CmdletUtilities.GetRuntime(this);
        var provider = runtime.FindProvider(Provider);
        if (provider is null)
        {
            CmdletUtilities.WriteFailure(this, new ArgumentException($"The provider '{Provider}' does not exist."), "ProviderNotFound", ErrorCategory.ObjectNotFound, Provider);
            return;
        }

        try
        {
            var values = provider.DirectoryHierarchy.Select(parameter =>
            {
                if (!MyInvocation.BoundParameters.TryGetValue(parameter, out var value) || string.IsNullOrWhiteSpace(value?.ToString()))
                {
                    throw new ArgumentException($"The parameter '{parameter}' is required for provider '{Provider}'.");
                }

                return value.ToString()!;
            }).ToArray();
            var repositoryPath = runtime.BuildRepositoryPath(provider, values);
            if (!CmdletUtilities.TryRunGit(this, ["init", repositoryPath], null, out var result))
            {
                return;
            }

            runtime.InvalidateRepositoryCache();
            CmdletUtilities.WriteGitOutput(this, result);
        }
        catch (Exception exception) when (exception is ArgumentException or InvalidOperationException or PathTooLongException)
        {
            CmdletUtilities.WriteFailure(this, exception, "RepositoryCreationFailed", ErrorCategory.InvalidArgument);
        }
    }
}

[Cmdlet(VerbsLifecycle.Install, "Repository", SupportsShouldProcess = true, ConfirmImpact = ConfirmImpact.Medium)]
[OutputType(typeof(string))]
public sealed class InstallRepositoryCommand : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0)]
    public string Url { get; set; } = string.Empty;

    [Parameter]
    public SwitchParameter Force { get; set; }

    protected override void ProcessRecord()
    {
        var runtime = CmdletUtilities.GetRuntime(this);
        GitProvider? provider;
        System.Text.RegularExpressions.Match? match;
        try
        {
            provider = runtime.MatchProvider(Url, out match);
        }
        catch (System.Text.RegularExpressions.RegexMatchTimeoutException exception)
        {
            CmdletUtilities.WriteFailure(this, exception, "ProviderPatternTimedOut", ErrorCategory.InvalidData, Url);
            return;
        }

        if (provider is null || match is null)
        {
            CmdletUtilities.WriteFailure(this, new ArgumentException($"No provider found for repository URL '{Url}'."), "ProviderNotFoundForUrl", ErrorCategory.InvalidArgument, Url);
            return;
        }

        var hierarchyValues = new List<string>();
        foreach (var segment in provider.DirectoryHierarchy)
        {
            var group = match.Groups[segment];
            if (!group.Success)
            {
                CmdletUtilities.WriteFailure(this, new ArgumentException($"The provider URL pattern did not capture '{segment}'."), "ProviderCaptureMissing", ErrorCategory.InvalidData, Url);
                return;
            }

            hierarchyValues.Add(group.Value);
        }

        string repositoryPath;
        try
        {
            repositoryPath = runtime.BuildRepositoryPath(provider, hierarchyValues);
        }
        catch (Exception exception) when (exception is ArgumentException or InvalidOperationException or PathTooLongException)
        {
            CmdletUtilities.WriteFailure(this, exception, "InvalidRepositoryPath", ErrorCategory.InvalidArgument, Url);
            return;
        }

        if (Directory.Exists(repositoryPath) || File.Exists(repositoryPath))
        {
            if (!Force)
            {
                CmdletUtilities.WriteFailure(this, new IOException("Target directory already exists. Use -Force to overwrite."), "RepositoryTargetExists", ErrorCategory.ResourceExists, repositoryPath);
                return;
            }

            if (!ShouldProcess(repositoryPath, "Remove existing repository directory"))
            {
                return;
            }

            var currentPath = CmdletUtilities.CurrentPath(this);
            WriteVerbose($"Current location is '{currentPath}'; replacement target is '{repositoryPath}'.");
            if (CmdletUtilities.IsWithinDirectory(currentPath, repositoryPath))
            {
                WriteVerbose($"Moving out of '{repositoryPath}' before replacing it.");
                SessionState.Path.SetLocation(Path.GetDirectoryName(repositoryPath)!);
            }

            try
            {
                CmdletUtilities.DeleteFileSystemEntry(repositoryPath);
                runtime.InvalidateRepositoryCache();
            }
            catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
            {
                CmdletUtilities.WriteFailure(this, exception, "RepositoryRemovalFailed", ErrorCategory.WriteError, repositoryPath);
                return;
            }
        }
        else if (!ShouldProcess(repositoryPath, "Clone repository"))
        {
            return;
        }

        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(repositoryPath)!);
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
        {
            CmdletUtilities.WriteFailure(this, exception, "RepositoryParentCreationFailed", ErrorCategory.WriteError, repositoryPath);
            return;
        }

        if (!CmdletUtilities.TryRunGit(this, ["clone", Url, repositoryPath], null, out var result))
        {
            return;
        }

        CmdletUtilities.WriteGitOutput(this, result);
        SessionState.Path.SetLocation(repositoryPath);
        runtime.InvalidateRepositoryCache();
    }
}

[Cmdlet(VerbsCommon.Remove, "Branch", DefaultParameterSetName = "ByName", SupportsShouldProcess = true, ConfirmImpact = ConfirmImpact.High)]
[OutputType(typeof(void))]
public sealed class RemoveBranchCommand : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0, ParameterSetName = "ByName")]
    public string? Name { get; set; }

    [Parameter(ParameterSetName = "ByName")]
    public SwitchParameter Remote { get; set; }

    [Parameter(Mandatory = true, ParameterSetName = "Gone")]
    public SwitchParameter Gone { get; set; }

    protected override void ProcessRecord()
    {
        var path = CmdletUtilities.CurrentPath(this);
        if (!CmdletUtilities.IsRepository(this, path))
        {
            CmdletUtilities.WriteFailure(this, new InvalidOperationException("Command needs to be run inside a git repository. Aborting."), "NotInGitRepository", ErrorCategory.InvalidOperation, path);
            return;
        }

        if (ParameterSetName == "Gone")
        {
            RemoveGoneBranches(path);
            return;
        }

        if (Remote)
        {
            RemoveRemoteBranch(path);
        }
        else
        {
            RemoveLocalBranch(path);
        }
    }

    private void RemoveLocalBranch(string path)
    {
        WriteVerbose($"Checking local branch '{Name}' in '{path}'.");
        if (string.IsNullOrWhiteSpace(Name) ||
            !CmdletUtilities.TryRunGit(this, ["check-ref-format", "--branch", Name], path, out _) ||
            !CmdletUtilities.TryRunGit(this, ["for-each-ref", "--format=%(refname:short)", "refs/heads"], path, out var refs))
        {
            return;
        }

        var branchNames = refs.StandardOutput.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries);
        WriteVerbose($"Found local branches: {string.Join(", ", branchNames)}.");
        if (!branchNames.Contains(Name, StringComparer.Ordinal))
        {
            CmdletUtilities.WriteFailure(this, new ItemNotFoundException($"Local branch '{Name}' was not found."), "BranchNotFound", ErrorCategory.ObjectNotFound, Name);
            return;
        }

        if (ShouldProcess(Name!, "Delete local branch") &&
            CmdletUtilities.TryRunGit(this, ["branch", "-d", Name!], path, out var result))
        {
            CmdletUtilities.WriteGitOutput(this, result);
        }
    }

    private void RemoveRemoteBranch(string path)
    {
        if (string.IsNullOrWhiteSpace(Name) ||
            !CmdletUtilities.TryRunGit(this, ["for-each-ref", "--format=%(refname:short)", "refs/remotes"], path, out var refs))
        {
            return;
        }

        var branch = refs.StandardOutput.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries)
            .FirstOrDefault(reference => string.Equals(reference, Name, StringComparison.Ordinal));
        if (branch is null || branch.EndsWith("/HEAD", StringComparison.Ordinal))
        {
            CmdletUtilities.WriteFailure(this, new ItemNotFoundException($"Remote branch '{Name}' was not found."), "BranchNotFound", ErrorCategory.ObjectNotFound, Name);
            return;
        }

        var separator = branch.IndexOf('/');
        if (separator <= 0 || separator == branch.Length - 1)
        {
            CmdletUtilities.WriteFailure(this, new ArgumentException("Remote branch names must use the form 'remote/branch'."), "InvalidRemoteBranch", ErrorCategory.InvalidArgument, Name);
            return;
        }

        var remoteName = branch[..separator];
        var remoteBranchName = branch[(separator + 1)..];
        if (ShouldProcess(branch, "Delete remote branch") &&
            CmdletUtilities.TryRunGit(this, ["push", remoteName, "--delete", remoteBranchName], path, out var result))
        {
            CmdletUtilities.WriteGitOutput(this, result);
        }
    }

    private void RemoveGoneBranches(string path)
    {
        if (!ShouldProcess(path, "Fetch and prune remote branches") ||
            !CmdletUtilities.TryRunGit(this, ["fetch", "--prune"], path, out _) ||
            !CmdletUtilities.TryRunGit(this, ["for-each-ref", "--format=%(refname:short) %(upstream:track)", "refs/heads"], path, out var result))
        {
            return;
        }

        var goneBranches = result.StandardOutput.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries)
            .Where(line => line.EndsWith(" [gone]", StringComparison.Ordinal))
            .Select(line => line[..^" [gone]".Length].TrimEnd())
            .Where(branch => branch.Length > 0)
            .ToArray();

        if (goneBranches.Length == 0)
        {
            WriteObject("No gone branches found that need cleanup.");
            return;
        }

        foreach (var branch in goneBranches)
        {
            if (ShouldProcess(branch, "Force-delete branch with a gone upstream") &&
                CmdletUtilities.TryRunGit(this, ["branch", "-D", branch], path, out var deletion))
            {
                CmdletUtilities.WriteGitOutput(this, deletion);
            }
        }
    }
}
