function Start-LoadingSequence {
	$Host.UI.RawUI.WindowTitle = "Loading profile..."

	New-Item -Path Function:\ -Name Global:Write-Host -Value $WriteHostFunction | Out-Null
	New-Item -Path Function:\ -Name Global:Import-Module -Value $ImportModuleFunction | Out-Null
	Set-ColorMapping

	Write-Host "Loading global profile for $(Get-ProfileName $MyInvocation.PSCommandPath)"
}
