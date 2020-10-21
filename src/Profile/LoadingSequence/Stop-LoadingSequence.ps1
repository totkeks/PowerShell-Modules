function Stop-LoadingSequence {
	Invoke-LocalProfile

	# setup prompt
	# stacking depth (shell inside shell)
	# background jobs
	# global (per OS?) and local directory mappings

	Write-Host
	Write-Greeting
	Write-Host

	Remove-Item Function:Write-Host
}
