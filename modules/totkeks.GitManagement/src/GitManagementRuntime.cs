using System.Collections;
using System.Collections.Specialized;
using System.Diagnostics;
using System.Management.Automation;
using System.Text.RegularExpressions;

namespace Totkeks.GitManagement;

public sealed class GitProvider
{
    public GitProvider(string name, string urlPattern, string[] directoryHierarchy)
    {
        Name = name;
        UrlPattern = urlPattern;
        DirectoryHierarchy = directoryHierarchy;
        UrlRegex = new Regex(urlPattern, RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant, TimeSpan.FromSeconds(1));
    }

    public string Name { get; }
    public string UrlPattern { get; }
    public string[] DirectoryHierarchy { get; }
    internal Regex UrlRegex { get; }

    internal PSObject ToPowerShellObject()
    {
        var result = new PSObject();
        result.TypeNames.Insert(0, "GitManagement.GitProvider");
        result.Properties.Add(new PSNoteProperty(nameof(Name), Name));
        result.Properties.Add(new PSNoteProperty(nameof(UrlPattern), UrlPattern));
        result.Properties.Add(new PSNoteProperty(nameof(DirectoryHierarchy), DirectoryHierarchy.ToArray()));
        return result;
    }
}

public sealed class GitRepository
{
    internal GitRepository(string provider, string path, OrderedDictionary properties)
    {
        Provider = provider;
        Path = path;
        Properties = properties;
    }

    public string Provider { get; }
    public string Path { get; }
    public OrderedDictionary Properties { get; }

    internal PSObject ToPowerShellObject()
    {
        var properties = new OrderedDictionary(StringComparer.OrdinalIgnoreCase);
        foreach (DictionaryEntry property in Properties)
        {
            properties.Add(property.Key, property.Value);
        }

        var result = new PSObject();
        result.TypeNames.Insert(0, "GitManagement.GitRepository");
        result.Properties.Add(new PSNoteProperty(nameof(Provider), Provider));
        result.Properties.Add(new PSNoteProperty(nameof(Path), Path));
        result.Properties.Add(new PSNoteProperty(nameof(Properties), properties));
        return result;
    }
}

public sealed class GitManagementRuntime
{
    private readonly object _sync = new();
    private readonly Dictionary<string, GitProvider> _providers = new(StringComparer.OrdinalIgnoreCase);
    private IReadOnlyList<GitRepository>? _repositories;
    private DateTimeOffset? _lastRepositoryScan;
    private string? _baseDirectory;

    private GitManagementRuntime()
    {
        AddProviderCore("Azure", @"https://(?:\w+@)?dev.azure.com/(?<Organization>[\w-]+)/(?<Project>[\w-]+)/_git/(?<Repository>[\w-]+)", ["Organization", "Project", "Repository"]);
        AddProviderCore("GitHub", @"https://github\.com/(?<UserOrOrganization>[\w-]+)/(?<Repository>[\w-]+)\.git", ["UserOrOrganization", "Repository"]);
        AddProviderCore("Bitbucket", @"https://(?:\w+@)?bitbucket.org/(?<User>[\w-]+)/(?<Repository>[\w-]+)\.git", ["User", "Repository"]);
    }

    public static GitManagementRuntime CreateDefault() => new();

    public string? BaseDirectory
    {
        get
        {
            lock (_sync)
            {
                return _baseDirectory;
            }
        }
    }

    public void SetBaseDirectory(string path)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(path);
        if (!Directory.Exists(path))
        {
            throw new DirectoryNotFoundException($"The path '{path}' is not an existing directory.");
        }

        var resolvedPath = Path.GetFullPath(path);
        lock (_sync)
        {
            _baseDirectory = resolvedPath;
            InvalidateRepositoryCacheCore();
        }
    }

    public string GetRequiredBaseDirectory()
    {
        lock (_sync)
        {
            return _baseDirectory ?? throw new InvalidOperationException("No git base directory set.");
        }
    }

    public IReadOnlyList<GitProvider> GetProviders()
    {
        lock (_sync)
        {
            return _providers.Values.OrderBy(provider => provider.Name, StringComparer.OrdinalIgnoreCase).ToArray();
        }
    }

    public GitProvider? FindProvider(string name)
    {
        lock (_sync)
        {
            return _providers.GetValueOrDefault(name);
        }
    }

    public void AddProvider(string name, string urlPattern, string[] directoryHierarchy)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);
        ArgumentException.ThrowIfNullOrWhiteSpace(urlPattern);
        ArgumentNullException.ThrowIfNull(directoryHierarchy);

        if (!IsSafePathSegment(name))
        {
            throw new ArgumentException("Provider names must be simple directory names.", nameof(name));
        }

        if (directoryHierarchy.Length == 0 || !directoryHierarchy.Contains("Repository", StringComparer.Ordinal))
        {
            throw new ArgumentException("The directory hierarchy must contain the 'Repository' element.", nameof(directoryHierarchy));
        }

        if (!directoryHierarchy.All(IsSafePathSegment) ||
            directoryHierarchy.Distinct(StringComparer.OrdinalIgnoreCase).Count() != directoryHierarchy.Length ||
            directoryHierarchy.Any(segment => !Regex.IsMatch(segment, @"^[A-Za-z_][A-Za-z0-9_]*$", RegexOptions.CultureInvariant)))
        {
            throw new ArgumentException("Directory hierarchy entries must be unique PowerShell parameter names and simple path names.", nameof(directoryHierarchy));
        }

        GitProvider provider;
        try
        {
            provider = new GitProvider(name, urlPattern, directoryHierarchy.ToArray());
        }
        catch (ArgumentException exception)
        {
            throw new ArgumentException($"The provider URL pattern is invalid: {exception.Message}", nameof(urlPattern), exception);
        }

        if (!provider.UrlRegex.GetGroupNames().Contains("Repository", StringComparer.Ordinal))
        {
            throw new ArgumentException("The URL pattern must contain the named capturing group 'Repository'.", nameof(urlPattern));
        }

        lock (_sync)
        {
            AddProviderCore(provider);
            InvalidateRepositoryCacheCore();
        }
    }

    public bool RemoveProvider(string name)
    {
        lock (_sync)
        {
            var removed = _providers.Remove(name);
            if (removed)
            {
                InvalidateRepositoryCacheCore();
            }

            return removed;
        }
    }

    public GitProvider? MatchProvider(string url, out Match? match)
    {
        foreach (var provider in GetProviders())
        {
            var currentMatch = provider.UrlRegex.Match(url);
            if (currentMatch.Success)
            {
                match = currentMatch;
                return provider;
            }
        }

        match = null;
        return null;
    }

    public string BuildRepositoryPath(GitProvider provider, IReadOnlyList<string> values)
    {
        if (values.Count != provider.DirectoryHierarchy.Length)
        {
            throw new ArgumentException($"Provider '{provider.Name}' requires {provider.DirectoryHierarchy.Length} hierarchy values.", nameof(values));
        }

        if (values.Any(value => !IsSafePathSegment(value)))
        {
            throw new ArgumentException("Repository hierarchy values must be simple directory names.", nameof(values));
        }

        var baseDirectory = GetRequiredBaseDirectory();
        var providerRoot = Path.GetFullPath(Path.Combine(baseDirectory, provider.Name));
        var repositoryPath = Path.GetFullPath(values.Aggregate(providerRoot, Path.Combine));
        var relativePath = Path.GetRelativePath(providerRoot, repositoryPath);
        if (relativePath == "." || relativePath == ".." || relativePath.StartsWith($"..{Path.DirectorySeparatorChar}", StringComparison.Ordinal))
        {
            throw new InvalidOperationException("The repository path must remain under its provider directory.");
        }

        return repositoryPath;
    }

    public IReadOnlyList<GitRepository> GetRepositories(bool refresh = false)
    {
        lock (_sync)
        {
            var isStale = _lastRepositoryScan is null || DateTimeOffset.UtcNow - _lastRepositoryScan > TimeSpan.FromMinutes(5);
            if (_repositories is not null && !refresh && !isStale)
            {
                return _repositories;
            }

            var baseDirectory = GetRequiredBaseDirectory();
            var repositories = new List<GitRepository>();
            foreach (var provider in _providers.Values.OrderBy(item => item.Name, StringComparer.OrdinalIgnoreCase))
            {
                var providerRoot = Path.Combine(baseDirectory, provider.Name);
                if (!Directory.Exists(providerRoot))
                {
                    continue;
                }

                DiscoverRepositories(provider, providerRoot, providerRoot, repositories);
            }

            _repositories = repositories;
            _lastRepositoryScan = DateTimeOffset.UtcNow;
            return _repositories;
        }
    }

    public void InvalidateRepositoryCache()
    {
        lock (_sync)
        {
            InvalidateRepositoryCacheCore();
        }
    }

    private static void DiscoverRepositories(GitProvider provider, string providerRoot, string currentDirectory, List<GitRepository> repositories)
    {
        if (Directory.Exists(Path.Combine(currentDirectory, ".git")) || File.Exists(Path.Combine(currentDirectory, ".git")))
        {
            var relativePath = Path.GetRelativePath(providerRoot, currentDirectory);
            var segments = relativePath.Split([Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar], StringSplitOptions.RemoveEmptyEntries);
            if (segments.Length == provider.DirectoryHierarchy.Length)
            {
                var properties = new OrderedDictionary(StringComparer.OrdinalIgnoreCase);
                for (var index = 0; index < segments.Length; index++)
                {
                    properties.Add(provider.DirectoryHierarchy[index], segments[index]);
                }

                repositories.Add(new GitRepository(provider.Name, currentDirectory, properties));
            }

            return;
        }

        foreach (var child in Directory.EnumerateDirectories(currentDirectory))
        {
            if ((File.GetAttributes(child) & FileAttributes.ReparsePoint) == 0)
            {
                DiscoverRepositories(provider, providerRoot, child, repositories);
            }
        }
    }

    private void AddProviderCore(string name, string urlPattern, string[] directoryHierarchy)
    {
        AddProviderCore(new GitProvider(name, urlPattern, directoryHierarchy));
    }

    private void AddProviderCore(GitProvider provider)
    {
        if (_providers.ContainsKey(provider.Name))
        {
            throw new InvalidOperationException($"The provider '{provider.Name}' already exists.");
        }

        _providers.Add(provider.Name, provider);
    }

    private void InvalidateRepositoryCacheCore()
    {
        _repositories = null;
        _lastRepositoryScan = null;
    }

    private static bool IsSafePathSegment(string? value) =>
        !string.IsNullOrWhiteSpace(value) &&
        value is not "." and not ".." &&
        value.IndexOfAny([Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar]) < 0 &&
        !Path.IsPathRooted(value);
}

internal sealed record GitProcessResult(int ExitCode, string StandardOutput, string StandardError);

internal static class GitProcess
{
    internal static GitProcessResult Run(IReadOnlyList<string> arguments, string? workingDirectory = null)
    {
        var startInfo = new ProcessStartInfo("git")
        {
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true
        };

        if (workingDirectory is not null)
        {
            startInfo.WorkingDirectory = workingDirectory;
        }

        foreach (var argument in arguments)
        {
            startInfo.ArgumentList.Add(argument);
        }

        using var process = new Process { StartInfo = startInfo };
        if (!process.Start())
        {
            throw new InvalidOperationException("Unable to start git.");
        }

        var standardOutputTask = process.StandardOutput.ReadToEndAsync();
        var standardErrorTask = process.StandardError.ReadToEndAsync();
        process.WaitForExit();
        return new GitProcessResult(process.ExitCode, standardOutputTask.GetAwaiter().GetResult(), standardErrorTask.GetAwaiter().GetResult());
    }
}
