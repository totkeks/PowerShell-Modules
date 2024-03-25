$UserModulePath = $env:PSModulePath.Split(";") | Where-Object { $_.contains($env:USERNAME) } | Select-Object -First 1

$Modules = @(
	"GitManagement"
)

foreach ($module in $Modules) {
	$sourcePath = Join-Path "src" $module
	$targetPath = Join-Path $UserModulePath $module

	Write-Output "Removing existing module $module from $targetPath"
	Remove-Item $targetPath -Recurse -ErrorAction SilentlyContinue

	Write-Output "Copying module $module from $sourcePath to $targetPath"
	Copy-Item $sourcePath $targetPath -Recurse
}
