function Invoke-HostProfile {
	$hostname = ($env:COMPUTERNAME).toLower()
	$hostProfile = (Join-Path $ProfileManagement.ProfileDirectory $hostname) + ".ps1"

	if (Test-Path $hostProfile) {
		Write-Host "Loading host profile for $hostname"
		. $hostProfile
	}
}
