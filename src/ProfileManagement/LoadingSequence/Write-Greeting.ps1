function Write-Greeting {
	$username = $IsWindows ? ([wmi] "win32_userAccount.Domain='$env:USERDOMAIN',Name='$env:USERNAME'").FullName : $env:USERNAME
	$computername = hostname
	$os = $PSVersionTable.OS
	$psversion = $PSVersionTable.PSVersion

	Write-Host "Hello $username, welcome to $computername!"
	Write-Host "You are running PowerShell $psversion on $os."
}
