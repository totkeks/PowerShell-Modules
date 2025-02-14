function Install-Dotfiles {
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(Mandatory, HelpMessage = 'Path to the source dotfiles directory.')]
		[string] $Path,

		[Parameter(HelpMessage = 'Path to the destination directory, defaults to user home directory.')]
		[string] $Destination = $HOME
	)

	$yesToAll = $false
	$noToAll = $false

	Get-ChildItem -Recurse -File $Path | ForEach-Object {
		$relativePath = [IO.Path]::GetRelativePath($Path, $_.FullName)
		$targetPath = [IO.Path]::Combine($Destination, $relativePath)

		Write-Verbose "Processing $relativePath"

		$targetDir = Split-Path $targetPath
		if (!(Test-Path $targetDir)) {
			Write-Verbose "Creating directory $targetDir"
			New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
		}

		$newContent = Resolve-Content $_

		if (Test-Path $targetPath) {
			$currentContent = Get-Content $targetPath
			$diff = Compare-Object $currentContent $newContent

			if (-not $diff) {
				Write-Verbose 'Source and target file are identical, skipping replacement'
				return
			}

			$tempCurrent = New-TemporaryFile
			$tempNew = New-TemporaryFile
			$currentContent | Out-File $tempCurrent -Force
			$newContent | Out-File $tempNew -Force

			& code --diff $tempCurrent $tempNew

			if (-not ($PSCmdlet.ShouldContinue($targetPath, 'Replace existing file?', [ref]$yesToAll, [ref]$noToAll))) {
				return
			}
		}

		Write-Verbose "Writing $relativePath to $targetPath"
		$newContent | Out-File $targetPath -Force
	}

	Save-Config
}
