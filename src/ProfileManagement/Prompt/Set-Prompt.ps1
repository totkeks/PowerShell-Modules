Function Set-Prompt {
	Function Global:Prompt {
		$LastExecutionSuccessful = $?
		$Host.UI.RawUI.WindowTitle = $PWD.Path

		If (!$LastExecutionSuccessful) { Write-Host "✘ " -NoNewline -ForegroundColor Red }

		If (Test-Administrator) {
			$Host.UI.RawUI.WindowTitle = $ProfileManagement.Elevated + " " + $Host.UI.RawUI.WindowTitle
			Write-Host "$($ProfileManagement.Elevated) " -NoNewline
		}

		# number of background jobs

		$path = " " + $(Select-PathAlias $PWD.Path) + " "
		$path = $path -replace [regex]::Escape([System.IO.Path]::DirectorySeparatorChar), " `u{e0b1} "

		Write-Host "[$(Get-Date -Format "HH:mm:ss")] " -NoNewline -ForegroundColor Red
		Write-Host -NoNewline -ForegroundColor Blue -BackgroundColor DarkGray $path
		Write-Host "`u{e0b0}" -NoNewline -ForegroundColor DarkGray
		Return " "
	}
}
