using namespace System.Management.Automation

class ExistingRepositoriesGenerator : IValidateSetValuesGenerator {
	[string[]] GetValidValues() {
		return (Find-GitRepositories).Properties.Repository | Sort-Object
	}
}
