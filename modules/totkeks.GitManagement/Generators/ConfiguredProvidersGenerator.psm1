using namespace System.Management.Automation

class ConfiguredProvidersGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return (Get-GitProvider).Name
	}
}
