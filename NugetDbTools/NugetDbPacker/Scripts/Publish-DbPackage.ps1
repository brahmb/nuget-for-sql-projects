function Publish-DbPackage {
	<#.Synopsis
	Publish a NuGet package for the DB project to the local NuGet server
	.DESCRIPTION
    Tests if the latest version of the project has been published.
    
    If not, a new package is created and is pushed to the NuGet server
	.EXAMPLE
	Publish-DbPackage -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sqlproj file of the project being published
        [string]$ProjectPath,
		# The solution file
		[string]$SolutionPath
	)
    $configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
    $projFolder = Split-Path $ProjectPath -Resolve
    $nugetFolder = [IO.Path]::Combine($projFolder, 'NuGet')
	$solutionFolder = Split-Path $SolutionPath
    if (Test-Path $configPath)
    {
        $settings = Import-NuGetSettings -NugetConfigPath $configPath -SolutionPath $SolutionPath
        $id = $settings.nugetSettings.Id
        $version = $settings.nugetSettings.version
        if (-not (Test-NuGetVersionExists -Id $id -Version $version)) {
            $nugetPackage = [IO.Path]::Combine($solutionFolder, "$id.$version.nupkg")
            Initialize-DbPackage -ProjectPath $ProjectPath -SolutionPath $SolutionPath
            if ($env:USERNAME -EQ 'Builder') {
				Publish-NuGetPackage -PackagePath $nugetPackage
				Remove-NugetFolder $nugetFolder
			}
        }
    }
}