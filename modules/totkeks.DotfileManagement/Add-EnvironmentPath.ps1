function Add-EnvironmentPath {
	param (
		[Parameter(Mandatory, HelpMessage = "Path to add to the PATH.")]
		[ValidateNotNullOrWhiteSpace()]
		[string] $Path
	)

	$envPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User) -split [IO.Path]::PathSeparator

	if ($envPath -notcontains $Path) {
		Write-Verbose "Adding $Path to PATH"

		$envPath += $Path
		[Environment]::SetEnvironmentVariable("PATH", $envPath -join [IO.Path]::PathSeparator, [EnvironmentVariableTarget]::User)
		[Environment]::SetEnvironmentVariable("PATH", $envPath -join [IO.Path]::PathSeparator, [EnvironmentVariableTarget]::Process)
	}
	else {
		Write-Verbose "$Path is already in PATH"
	}
}
