function Save-Config {
	Write-Verbose "Saving configuration to $($DotfileManagement.ConfigPath)"

	$DotfileManagement.Config | ConvertTo-Json | Set-Content $DotfileManagement.ConfigPath
}
