$projectType = 'Project'
$id="Prefix.Name"
$contentType='lib'

try {
	$slnDir = (Get-Item "$PSScriptRoot").FullName
	$nugetFolder = "$slnDir\NuGet"
	$nuspecPath = "$slnDir\Package.nuspec"
	$nugetBinFolder = "$nugetFolder\$contentType"
	pushd $slnDir

	$loaded = $false
	if (-not (Get-Module NuGetProjectPacker)) {
	$loaded = $true
		Import-Module "$slnDir\PowerShell\NuGetProjectPacker.psm1"
}

	$version = Set-NuspecVersion -Path $slnDir\Package.nuspec -ProjectFolder $slnDir
	if ($version -like '*.0'){
		throw "Invalid version $version"
	}

	$nugetPackagePath = "$slnDir\$id.$version.nupkg"

	if (Test-Path $nugetFolder) {
		del $nugetFolder\* -Recurse -Force
		rmdir $nugetFolder
}

	md "$nugetFolder" | Out-Null
	"content\$contentType" | % { mkdir $nugetFolder\$_ | Out-Null }

	('Project1','Project2','Project3','Project4', 'Project5') | % {
		[string]$projSubPath = $_
		$projName = Split-Path $projSubPath -Leaf
		$projDir = "$slnDir\$projName"
		$projPath = "$projDir\$projName.csproj"
		$projBinFolder = "$projDir\bin\Debug"
	
		Import-ArtifactProject -ProjectPath $projPath -ProjBinFolder $projBinFolder -ArtifactBinFolder $nugetBinFolder -DefaultAssemblyName $projName
	}

	if (-not (Test-NuGetVersionExists -Id $id -Version $version)){
		NuGet pack $slnDir\Package.nuspec -BasePath "$nugetFolder" -OutputDirectory $slnDir
	    Publish-NuGetPackage -PackagePath $nugetPackagePath
	}

	Remove-NugetFolder $nugetFolder
	if (Test-Path $nugetPackagePath)
	{
		del $nugetPackagePath
	}
	if ($loaded) {
		Remove-Module NuGetProjectPacker -ErrorAction Ignore
	}
} catch {
	Write-Host "$id packaging failed: $($_.Exception.Message)" -ForegroundColor Red
	Exit 1
} finally {
	popd
}
