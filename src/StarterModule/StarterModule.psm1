$PublicScripts = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$PrivateScripts = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

Foreach ($Script in @($PublicScripts + $PrivateScripts)) {
	Try {
		. $Script.FullName
	}
	Catch {
		Write-Error "Failed to import script $($Script.FullName): $_"
	}
}

Export-ModuleMember -Function $PublicScripts.BaseName
