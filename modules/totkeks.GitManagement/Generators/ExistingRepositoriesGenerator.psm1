using namespace System.Management.Automation

class ExistingRepositoriesGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return (Get-GitRepository).Properties.Repository | Sort-Object
	}
}
