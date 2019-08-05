function Get-NuGetDbToolsConfigPath {
	if ($Global:testing) {
		"TestDrive:\Configuration\NugetDbTools.config"
	} else {
		if (Test-Path "$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config") {
			"$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config"
		} elseif (Test-Path "$PSScriptRoot\..\JamieO53\NugetDbTools\JamieO53\NugetDbTools\NugetDbTools.config") {
			"$PSScriptRoot\..\JamieO53\NugetDbTools\JamieO53\NugetDbTools\NugetDbTools.config"
		} else {
			Log "Unable to find NuGetDbTools configuration"
		}
	}
}

