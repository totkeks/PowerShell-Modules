function Get-OutdatedModules {
	$installedModules = Get-Module -ListAvailable | Where-Object { $_.RepositorySourceLocation } |
		Get-Unique
	$onlineModules = $installedModules | ForEach-Object -Parallel { Find-Module $_.Name }

	$onlineModules.ForEach(
		{
			$onlineModule = $_
			$installedModule = $installedModules.Where( { $_.Name -eq $onlineModule.Name })

			if ($onlineModule.Version -gt $installedModule.Version) {
				[PSCustomObject]@{
					Name = $installedModule.name
					InstalledVersion = $installedModule.version
					OnlineVersion = $onlineModule.version
				}
			}
		}
	)
}

# $GetOutdatedModules = ${Function:Get-OutdatedModules}
# 	$Script:OutdatedModulesJob = Start-ThreadJob -StreamingHost (Get-Host) {
# 		$outdatedModules = & $using:GetOutdatedModules

# 		Write-Host $outdatedModules
# 	}

# Write-Output "`e[2J`e[2;2HFOOBAR`e[L"
