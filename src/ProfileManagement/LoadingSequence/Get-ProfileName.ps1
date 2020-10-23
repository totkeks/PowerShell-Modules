function Get-ProfileName {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Path
	)

	$profiles = $PROFILE | Select-Object -Property ($PROFILE | Get-Member -Type NoteProperty).Name
	$profileNames = @{}
	$profiles.PSObject.Properties.ForEach( { $profileNames[$_.Name] = $_.Value })
	($profileNames.GetEnumerator() | Where-Object { $_.Value -eq $Path }).Name
}
