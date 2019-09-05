﻿if (Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1" -Global -DisableNameChecking

$Global:testing = $true
$config = @"
<?xml version="1.0"?>
<configuration>
	<nugetLocalServer>
		<add key="ApiKey" value="Test Key"/>
		<add key="Source" value="Local Server"/>
		<add key="PushTimeout" value="123"/>
	</nugetLocalServer>
</configuration>
"@
Describe "Get-NuGetLocalPushTimeout" {
	$path = Get-NuGetDbToolsConfigPath
	$folder = Split-Path $path
	mkdir $folder
	$config | Set-Content -Path $path
	Context "Exists" {
		It "Runs" {
			Get-NuGetLocalPushTimeout | should be '123'
		}
	}
}
$Global:testing = $false
