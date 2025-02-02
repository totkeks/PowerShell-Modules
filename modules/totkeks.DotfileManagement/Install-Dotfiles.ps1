function Install-Dotfiles {
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(Mandatory, HelpMessage = "Path to the source dotfiles directory.")]
		[string] $Path,

		[Parameter(HelpMessage = "Path to the destination directory, defaults to user home directory.")]
		[string] $Destination = $HOME
	)

	$yesToAll = $false
	$noToAll = $false

	Get-ChildItem -Recurse -File $Path | ForEach-Object {
		$relativePath = [IO.Path]::GetRelativePath($Path, $_.FullName)
		$targetPath = [IO.Path]::Combine($Destination, $relativePath)

		Write-Verbose "Processing $relativePath"

		$newContent = Resolve-Content $_

		if (Test-Path $targetPath) {
			$currentContent = Get-Content $targetPath
			$diff = Compare-Object $currentContent $newContent

			if (-not $diff) {
				Write-Verbose "Source and target file are identical, skipping replacement"
				return
			}

			Write-Host "Differences found:"
			$diff | Format-Table

			if (-not ($PSCmdlet.ShouldContinue($targetPath, "Replace existing file?", [ref]$yesToAll, [ref]$noToAll))) {
				return
			}
		}

		Write-Verbose "Writing $relativePath to $targetPath"
		$newContent | Out-File $targetPath -Force
	}

	Save-Config
}
