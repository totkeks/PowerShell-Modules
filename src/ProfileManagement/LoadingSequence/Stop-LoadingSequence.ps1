function Stop-LoadingSequence {
	Write-Host "Finished loading global profile $($ProfileManagement.Checkmark)"
	Write-Host

	Invoke-HostProfile
	Write-Host "Finished loading host profile $($ProfileManagement.Checkmark)"
	Write-Host

	Set-Prompt
	Write-Greeting

	Remove-Item Function:Import-Module
	Remove-Item Function:Write-Host
	Write-Host
}
