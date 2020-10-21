$UserModulePath = $env:PSModulePath.Split(";") | Where-Object { $_.contains($env:USERNAME) } | Select-Object -First 1

$Modules = @(
	"GitManagement"
	"Profile"
)

foreach ($module in $Modules) {
	$sourcePath = Join-Path "src" $module
	$targetPath = Join-Path $UserModulePath $module

	Remove-Item $targetPath -Recurse -ErrorAction SilentlyContinue
	Copy-Item $sourcePath $targetPath -Recurse
}
