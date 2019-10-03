function Get-NuGetPackageVersion {
	<#.Synopsis
	Get the latest version number of the package
	.DESCRIPTION
	Retrieves the latest version number of the specified package in the local NuGet server
	.EXAMPLE
	$ver = Get-NuGetPackageVersion -PackageName 'BackOfficeAudit.Logging'
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The NuGet package name
		[string]$PackageName
	)
	$version = ''
	Invoke-Expression "nuget list $PackageName -Source '$(Get-NuGetLocalSource)'" | ForEach-Object {
		$nameVersion = $_ -split ' '
		if ($nameVersion[0] -eq $PackageName) {
			$version = $nameVersion[1]
		}
	}
	return $version
}