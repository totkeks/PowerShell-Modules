function Get-TemplateVariable {
	param(
		[string]$Name
	)

	$config = Get-Config
	$value = $config.PSObject.Properties[$Name]?.Value

	if ($null -eq $value) {
		$value = Read-Host "Please enter value for '$Name'"
		$config | Add-Member NoteProperty $Name $value
	}

	$value
}
