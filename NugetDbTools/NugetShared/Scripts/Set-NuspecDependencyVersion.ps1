function Set-NuspecDependencyVersion {
<#.Synopsis
	Set the dependency's version in the Project.nuspec file to the latest version on the server.
.DESCRIPTION
	Fetches the dependency's latest version number and sets it in the .nuspec file.
.EXAMPLE
	Set-NuspecDependencyVersion -Path .\Package.nuspec -Dependency NugetDbPacker
#>
    [CmdletBinding()]
    param
    (
        # The path of the .nuspec file
		[string]$Path,
		# The dependency name
		[string]$Dependency
	)

	$spec = gc $Path
	$dep = $spec | ? { $_ -like "*<dependency id=`"$Dependency`" version=`"*`"/>*"  }
	$oldVersion = ($dep -split '"')[3]
	$newVersion = Get-NuGetPackageVersion $Dependency
	$specText = $spec | Out-String
	$specText =  $specText.Replace($oldVersion, $newVersion).TrimEnd()
	$specText | Out-File -FilePath $Path -Encoding utf8 -Force
}