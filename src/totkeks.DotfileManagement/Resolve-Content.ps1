function Resolve-Content {
	param(
		[IO.FileInfo]$File
	)

	switch ($File.Extension) {
		# '.csv' {
		# 	$findPattern = [Regex]"<<(?<variable>\w+),(?<variable2>\w+)>>"
		# 	$replacePattern = [Regex]"<<$varName,$varName2>>"
		# }
		default {
			$findPattern = [Regex]"<<(?<variable>\w+)>>"
			$replacePattern = { [Regex]"<<$_>>" }
		}
	}

	Get-Content $File.FullName | ForEach-Object {
		$line = $_

		$findPattern.Matches($line)
		| Select-Object -ExpandProperty Groups
		| Where-Object Name -EQ "variable"
		| Select-Object -ExpandProperty Value -Unique
		| ForEach-Object {

			$name = $_
			$value = Get-TemplateVariable $name

			Write-Verbose "Replacing '$name' with '$value'"
			$line = (& $replacePattern $name).Replace($line, $value)
		}

		$line
	}
}
