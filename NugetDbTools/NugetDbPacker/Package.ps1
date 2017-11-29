$id='NuGetDbPacker'
$contentType='PowerShell'
$projDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)").Path
$slnDir = "$projDir\.."
pushd $projDir


$loaded = $false
if (-not (Get-Module NugetShared)) {
	$loaded = $true
	Import-Module "$projDir\bin\Debug\$id\NugetShared.psm1"
}

$version = Set-NuspecVersion -Path $projDir\Package.nuspec -ProjectFolder $projDir
Set-NuspecDependencyVersion -Path $projDir\Package.nuspec -Dependency 'NuGetShared'

if (Test-Path $projDir\NuGet) {
	del $projDir\NuGet\* -Recurse -Force
	rmdir $projDir\NuGet
}

md "$projDir\NuGet" | Out-Null
'tools','lib',"content\$contentType","content\PackageTools",'build' | % { md $projDir\NuGet\$_ | Out-Null }

copy "$projDir\bin\Debug\$id\$id.ps*1" "$projDir\NuGet\content\$contentType\"
copy "$slnDir\PackageTools\*" "$projDir\NuGet\content\PackageTools\"

NuGet pack $projDir\Package.nuspec -BasePath "$projDir\NuGet" -OutputDirectory $projDir
nuget push "$projDir\$id.$version.nupkg" (Get-NuGetLocalApiKey) -Source (Get-NuGetLocalSource)

del $projDir\NuGet\* -Recurse -Force
rmdir $projDir\NuGet
del "$projDir\$id.$version.nupkg"
if ($loaded) {
	Remove-Module NugetShared -ErrorAction Ignore
}
popd
