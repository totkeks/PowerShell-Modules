function Find-Repository {
	Param (
		[switch] $Refresh
	)

	filter FindDotGitDirectory {
		if (Test-Path $_\.git) {
			return $_
		}

		Get-ChildItem -Directory $_ | FindDotGitDirectory
	}

	if ($null -eq $GitManagement.Repositories -or $Refresh -or ((Get-Date) - $GitManagement.LastRepositoryScan).TotalSeconds -gt 300) {
		Write-Debug "Updating repository cache"

		$baseDirectory = Get-BaseDirectory
		$repositoryPaths = ($baseDirectory | FindDotGitDirectory).FullName
		$providers = Get-Provider

		$GitManagement.LastRepositoryScan = Get-Date
		$GitManagement.Repositories = $repositoryPaths | ForEach-Object {
			$splitPath = [io.path]::GetRelativePath($baseDirectory, $_).Split([io.path]::DirectorySeparatorChar)
			$provider = $providers | Where-Object Name -EQ $splitPath[0]
			$directories = $splitPath[1..($splitPath.Count - 1)]

			$repository = [PSCustomObject]@{
				PSTypeName = "GitManagement.GitRepository"
				Provider = $provider.Name
				Path = $_
			}

			$properties = [ordered]@{ }
			for ($ii = 0; $ii -lt $directories.Length; $ii++) {
				$hierarchicalDirectory = $provider.DirectoryHierarchy[$ii]
				$properties.Add($hierarchicalDirectory, $directories[$ii])
			}

			$repository | Add-Member Properties $properties
			$repository
		}
	}

	$GitManagement.Repositories
}

