function Get-Config {
	if ($null -eq $DotfileManagement.Config) {
		if (-not (Test-Path -Path $DotfileManagement.ConfigPath)) {
			New-Item $DotfileManagement.ConfigPath -ItemType File -Value "{}" -Force
		}

		$DotfileManagement.Config = Get-Content $DotfileManagement.ConfigPath -Raw | ConvertFrom-Json
	}

	$DotfileManagement.Config
}
