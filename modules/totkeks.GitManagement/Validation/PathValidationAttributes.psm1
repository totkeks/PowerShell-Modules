using namespace System.Management.Automation

class ValidatePathExistsAttribute : ValidateArgumentsAttribute {
	[void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics) {
		if (-not (Test-Path $arguments)) {
			throw [ValidationMetadataException]::new("The path '$arguments' does not exist.")
		}
	}
}
