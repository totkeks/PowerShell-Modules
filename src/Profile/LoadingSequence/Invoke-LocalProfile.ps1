function Invoke-LocalProfile {
	$hostname = ($env:COMPUTERNAME).toLower()
	$hostProfile = (Join-Path $ProfileDirectory $hostname) + ".ps1"

	if (Test-Path $hostProfile) {
		Write-Host "Loading host profile from $hostProfile"
		. $hostProfile
	}
}
