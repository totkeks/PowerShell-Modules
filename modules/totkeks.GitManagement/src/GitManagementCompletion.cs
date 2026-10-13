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

    public static CompletionResult[] CompleteRepositories(GitManagementRuntime runtime, string wordToComplete)
    {
        ArgumentNullException.ThrowIfNull(runtime);
        if (runtime.BaseDirectory is null)
        {
            return [];
        }

        return runtime.GetRepositories()
            .Select(repository => repository.Properties["Repository"]?.ToString())
            .Where(name => !string.IsNullOrEmpty(name) && name.StartsWith(wordToComplete ?? string.Empty, StringComparison.OrdinalIgnoreCase))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(name => name, StringComparer.OrdinalIgnoreCase)
            .Select(name => new CompletionResult(name!, name!, CompletionResultType.ParameterValue, name!))
            .ToArray();
    }
}
