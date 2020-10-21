function Start-LoadingSequence {
	$Script:ProfileDirectory = $MyInvocation.PSScriptRoot
	New-Item -Path Function:\ -Name Global:Write-Host -Value $WriteHostFunction | Out-Null
	Set-ColorMapping

	$Host.UI.RawUI.WindowTitle = "Loading profile..."
	Write-Host "Loading global profile from $($MyInvocation.PSCommandPath)"
}
