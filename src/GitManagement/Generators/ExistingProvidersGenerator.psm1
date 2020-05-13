using namespace System.Management.Automation

class ExistingProvidersGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return (Get-GitRepository).Provider | Sort-Object | Get-Unique
	}
}
