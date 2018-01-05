param (
	[string]$ProjectType = 'Db'
)
$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
$BootstrapFolder = "$SolutionFolder\Bootstrap"

if (Test-Path $BootstrapFolder) {
    del $BootstrapFolder\* -Recurse -Force
} else {
    mkdir $BootstrapFolder
}

$configPath = "$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config"
[xml]$config = Get-Content $configPath
$localSource = $config.configuration.nugetLocalServer.add | ? { $_.key -eq 'Source' } | % { $_.value }
$package = "NuGet$($ProjectType)Packer"

nuget install $package -Source $localSource -OutputDirectory $BootstrapFolder -ExcludeVersion

ls $BootstrapFolder -Directory | % {
    ls $_.FullName -Directory | % {
        if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
            mkdir "$SolutionFolder\$($_.Name)"
        }
		copy "$($_.FullName)\*" "$SolutionFolder\$($_.Name)"
    }
}

"powershell -Command `"& { .\Bootstrap.ps1 -ProjectType $ProjectType }`"" |
	sc "$SolutionFolder\Bootstrap.cmd" -Encoding UTF8

if (Test-Path "$SolutionFolder\Package.nuspec.txt") {
	Rename-Item "$SolutionFolder\Package.nuspec.txt" 'Package.nuspec'
}

del $BootstrapFolder -Include '*' -Recurse