using System.Collections;
using System.Management.Automation;

namespace Totkeks.GitManagement;

public static class GitManagementCompletion
{
    public static CompletionResult[] CompleteProviders(GitManagementRuntime runtime, string wordToComplete)
    {
        ArgumentNullException.ThrowIfNull(runtime);
        return runtime.GetProviders()
            .Select(provider => provider.Name)
            .Where(name => name.StartsWith(wordToComplete ?? string.Empty, StringComparison.OrdinalIgnoreCase))
            .Select(name => new CompletionResult(name, name, CompletionResultType.ParameterValue, name))
            .ToArray();
    }

    public static CompletionResult[] CompleteRepositories(GitManagementRuntime runtime, string wordToComplete, IDictionary? fakeBoundParameters = null)
    {
        ArgumentNullException.ThrowIfNull(runtime);
        if (runtime.BaseDirectory is null)
        {
            return [];
        }

        return runtime.GetRepositories()
            .Where(repository =>
            {
                if (TryGetBoundParameter(fakeBoundParameters, "Provider", out var provider) &&
                    !string.Equals(repository.Provider, provider?.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    return false;
                }

                foreach (var property in repository.Properties.Keys)
                {
                    var propertyName = property?.ToString();
                    if (string.IsNullOrEmpty(propertyName) || propertyName.Equals("Repository", StringComparison.OrdinalIgnoreCase) ||
                        !TryGetBoundParameter(fakeBoundParameters, propertyName, out var value))
                    {
                        continue;
                    }

                    if (!string.Equals(repository.Properties[propertyName]?.ToString(), value?.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        return false;
                    }
                }

                var name = repository.Properties["Repository"]?.ToString();
                return !string.IsNullOrEmpty(name) && name.StartsWith(wordToComplete ?? string.Empty, StringComparison.OrdinalIgnoreCase);
            })
            .OrderBy(repository => repository.Properties["Repository"]?.ToString(), StringComparer.OrdinalIgnoreCase)
            .ThenBy(repository => repository.Provider, StringComparer.OrdinalIgnoreCase)
            .ThenBy(GetRepositoryIdentity, StringComparer.OrdinalIgnoreCase)
            .Select(repository => new CompletionResult(
                BuildCompletionText(repository, fakeBoundParameters),
                repository.Properties["Repository"]?.ToString() ?? string.Empty,
                CompletionResultType.ParameterValue,
                GetRepositoryToolTip(repository)))
            .ToArray();
    }

    private static string BuildCompletionText(GitRepository repository, IDictionary? fakeBoundParameters)
    {
        var completion = new List<string> { QuotePowerShellLiteral(repository.Properties["Repository"]?.ToString() ?? string.Empty) };
        if (!TryGetBoundParameter(fakeBoundParameters, "Provider", out _))
        {
            completion.Add("-Provider");
            completion.Add(QuotePowerShellLiteral(repository.Provider));
        }

        foreach (DictionaryEntry property in repository.Properties)
        {
            var parameterName = property.Key?.ToString();
            if (string.IsNullOrEmpty(parameterName) ||
                parameterName.Equals("Repository", StringComparison.OrdinalIgnoreCase) ||
                parameterName.Equals("Name", StringComparison.OrdinalIgnoreCase) ||
                parameterName.Equals("Provider", StringComparison.OrdinalIgnoreCase) ||
                TryGetBoundParameter(fakeBoundParameters, parameterName, out _))
            {
                continue;
            }

            completion.Add($"-{parameterName}");
            completion.Add(QuotePowerShellLiteral(property.Value?.ToString() ?? string.Empty));
        }

        return string.Join(' ', completion);
    }

    private static bool TryGetBoundParameter(IDictionary? boundParameters, string name, out object? value)
    {
        if (boundParameters is not null)
        {
            foreach (DictionaryEntry entry in boundParameters)
            {
                if (string.Equals(entry.Key?.ToString(), name, StringComparison.OrdinalIgnoreCase))
                {
                    value = entry.Value;
                    return true;
                }
            }
        }

        value = null;
        return false;
    }

    private static string QuotePowerShellLiteral(string value) => $"'{value.Replace("'", "''", StringComparison.Ordinal)}'";

    private static IEnumerable<DictionaryEntry> GetHierarchyProperties(GitRepository repository) =>
        repository.Properties
            .Cast<DictionaryEntry>()
            .Where(property => !string.Equals(property.Key?.ToString(), "Repository", StringComparison.OrdinalIgnoreCase));

    private static string GetRepositoryIdentity(GitRepository repository)
    {
        var identity = string.Join("/", GetHierarchyProperties(repository).Select(property => property.Value?.ToString()));
        return string.IsNullOrEmpty(identity) ? "unknown" : identity;
    }

    private static string GetRepositoryToolTip(GitRepository repository)
    {
        var hierarchy = GetHierarchyProperties(repository)
            .Select(property =>
            {
                var propertyName = property.Key?.ToString() ?? string.Empty;
                var label = propertyName.Equals("UserOrOrganization", StringComparison.OrdinalIgnoreCase) ||
                            propertyName.Equals("Owner", StringComparison.OrdinalIgnoreCase)
                    ? "User"
                    : propertyName;
                return $"{label}: {property.Value}";
            });
        return string.Join("; ", hierarchy.Append($"Provider: {repository.Provider}"));
    }
}
