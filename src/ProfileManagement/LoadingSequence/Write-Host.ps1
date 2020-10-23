$Script:WriteHostFunction = {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline)]
		[string] $Message,

		[Parameter(Mandatory = $false)]
		[switch] $NoNewLine,

		[Parameter(Mandatory = $false)]
		[switch] $ContinueLine
	)

	Begin {
		if (-not $ContinueLine) {
			Microsoft.PowerShell.Utility\Write-Host -ForegroundColor Green -NoNewline $ProfileManagement.LinePrefix
		}
	}

	Process {
		$Color = $Host.UI.RawUI.ForegroundColor

		Microsoft.PowerShell.Utility\Write-Host -NoNewline -ForegroundColor $Color $Message
	}

	End {
		if (-not $NoNewLine) {
			Microsoft.PowerShell.Utility\Write-Host
		}
	}
}
