function Get-SolutionContent {
	<#.Synopsis
	Get the solution's dependency content
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	.EXAMPLE
	Get-SolutionContent -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$solutionFolder = Split-Path $SolutionPath
	$packageContentFolder = "$SolutionFolder\PackageContent"
	$packageFolder = "$SolutionFolder\packages"
	$contentFolder = Get-NuGetContentFolder
	$solutionContentFolder = "$SolutionFolder\$contentFolder"
	$archiveSolutionContentFolder = "$solutionContentFolder.$(Get-Date -Format 'yyyyMMddHHmm')"

	if (-not $contentFolder) {
		$configFolder = (Get-Item (Get-NuGetDbToolsConfigPath)).FullName
		Log "Content folder not specified in $configFolder" -Error
		exit 1
	}

	Log "Get solution packages: $SolutionPath"
	Get-SolutionPackages -SolutionPath $SolutionPath -ContentFolder $packageContentFolder

	if (Test-Path "$solutionFolder\Databases") {
		Log "Removing old database dacpacs"
		Remove-Item "$solutionFolder\Databases\*" -Recurse -Force -Exclude NugetDbPackerDb.Root.dacpac,master.dacpac
	}
	Log "Getting referenced database dacpacs"
	Get-ChildItem $packageContentFolder -Directory | ForEach-Object {
		Get-ChildItem $_.FullName -Directory | Where-Object { (Get-ChildItem $_.FullName -Exclude _._).Count -ne 0 } | ForEach-Object {
			if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
				mkdir "$SolutionFolder\$($_.Name)" | Out-Null
			}
			Copy-Item "$($_.FullName)\*" "$SolutionFolder\$($_.Name)\" -Recurse -Force
		}
	}

	Remove-Item $packageContentFolder\* -Recurse -Force
	Remove-Item $packageContentFolder -Recurse -Force

	$csPackage = @{}
	Get-ChildItem $solutionFolder\**\packages.config | ForEach-Object {
		[xml]$pc = Get-Content $_
		$pc.packages.package | ForEach-Object {
			New-Object -TypeName PSCustomObject -Property @{ id=$_.id; version=$_.version }
		}
	} | Sort-Object -Property id,version -Unique | ForEach-Object {
		$csPackage[$_.id] = $_.version
	}
	
	if ((Test-Path $packageFolder) -and (Get-ChildItem "$packageFolder\**\$contentFolder" -Recurse)) {
		if (Test-Path $solutionContentFolder) {
			[string[]]$exclude = Get-LockedFiles $solutionContentFolder
			if ($exclude.Count -gt 0) {
				Log -Warn "$solutionContentFolder contains locked files"
				$exclude | ForEach-Object {
					Log -Warn $_
				}
			}
			Log "Archiving $contentFolder to $archiveSolutionContentFolder"
			mkdir -Path $archiveSolutionContentFolder | Out-Null
			Copy-Item -Path $solutionContentFolder\* -Destination $archiveSolutionContentFolder -Recurse -Force -Exclude $exclude
			if ($exclude.Count -gt 0) {
				Log "Attempting to archive locked files"
				Copy-Item -Path $solutionContentFolder\* -Destination $archiveSolutionContentFolder -Recurse -Force -ErrorAction SilentlyContinue
			}
			Log "Clearing $contentFolder"
			Get-ChildItem $solutionContentFolder\* -Directory | ForEach-Object {
				$d = $_
				Log "Clearing $($d.Name) files"
				try {
					Remove-Item -Path $d -Force -Recurse -Exclude $exclude -ErrorAction Stop
				} catch {}
			}
			Log "Removing empty subfolders"
			Remove-Item -Path $solutionContentFolder\* -Recurse -Force -Exclude $exclude -ErrorAction SilentlyContinue
		} else {
			mkdir $solutionContentFolder | Out-Null
		}
		Log "Populating $contentFolder"
		$csPackage.Keys | Sort-Object | ForEach-Object {
			$id = $_
			$version = $csPackage[$id]
			$idContentFolder = "$packageFolder\$id.$version\content\$contentFolder"
			if (Test-Path $idContentFolder) {
				Copy-Item "$idContentFolder\*" "$solutionContentFolder\" -Recurse -Force
			}
		}
	}
}