function Set-ColorMapping {
	$Host.PrivateData.ErrorForegroundColor = [ConsoleColor]::Red
	$Host.PrivateData.WarningForegroundColor = [ConsoleColor]::Yellow
	$Host.PrivateData.DebugForegroundColor = [ConsoleColor]::Green
	$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::Blue
	$Host.PrivateData.ProgressForegroundColor = [ConsoleColor]::Gray

	$Host.PrivateData.ErrorBackgroundColor = [ConsoleColor]::DarkGray
	$Host.PrivateData.WarningBackgroundColor = [ConsoleColor]::DarkGray
	$Host.PrivateData.DebugBackgroundColor = [ConsoleColor]::DarkGray
	$Host.PrivateData.VerboseBackgroundColor = [ConsoleColor]::DarkGray
	$Host.PrivateData.ProgressBackgroundColor = [ConsoleColor]::Cyan

	$Script:Colors = @{
		"Command" = "`e[34;40m"
		"Comment" = "`e[93;40m"
		"ContinuationPrompt" = "`e[92;40m"
		"Emphasis" = "`e[36;40m"
		"Error" = "`e[31;40m"
		"Keyword" = "`e[35;40m"
		"Member" = "`e[97;40m"
		"Number" = "`e[97;40m"
		"Operator" = "`e[92;40m"
		"Parameter" = "`e[94;40m"
		"Selection" = "`e[30;47m"
		"String" = "`e[32;40m"
		"Type" = "`e[35;40m"
		"Variable" = "`e[91;40m"
	}

	Set-PSReadLineOption -Colors $Colors
}
