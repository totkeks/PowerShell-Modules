using namespace System.Management.Automation

class ConfiguredAliasesGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return (Get-PathAlias).Name
	}
}
