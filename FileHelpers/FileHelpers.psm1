<#
.SYNOPSIS
    A module containing helper functions for advanced file and directory manipulation.
.DESCRIPTION
    This module provides smart commands to Join Directories directories, intelligently change
    locations, get content from paths, and create files or directories based on the path string.
#>

<#
.SYNOPSIS
    Moves all files from a source directory and its subdirectories into a
    single destination directory.
#>
function Join-Directories
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(Mandatory = $true)]
		[string]$SourcePath,
		[string]$DestinationPath = $PWD,
		[switch]$Force
	)
	$source = Resolve-Path -Path $SourcePath
	$destination = Resolve-Path -Path $DestinationPath
	if (-not (Test-Path -Path $source -PathType Container))
	{ Write-Error "Source path '$source' is not a valid directory."; return 
	}
	if (-not (Test-Path -Path $destination -PathType Container))
	{ Write-Error "Destination path '$destination' is not a valid directory."; return 
	}
	$files = Get-ChildItem -Path $source -Recurse -File
	foreach ($file in $files)
	{
		$targetPath = Join-Path -Path $destination -ChildPath $file.Name
		if ($pscmdlet.ShouldProcess($file.FullName, "Move to $targetPath"))
		{
			Move-Item -Path $file.FullName -Destination $targetPath -Force:$Force
		}
	}
	Write-Host "Join Directories operation complete." -ForegroundColor Green
}

<#
.SYNOPSIS
    Intelligently changes the current location to the directory of a given path.
#>
function Set-SmartLocation
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	if (-not (Test-Path -Path $Path))
	{ Write-Error "The path '$Path' does not exist."; return 
	}
	$item = Get-Item -Path $Path
	if ($item.PSIsContainer)
	{ 
		Set-Location -Path $item.FullName 
	} else
	{
		Set-Location -Path $item.DirectoryName
		Write-Debug "Entering project $(Get-Location)"
		Enter-Project -UsePwd
	}
}

<#
.SYNOPSIS
    Intelligently gets the content of a path.
#>
function Get-SmartContent
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	if (-not (Test-Path -Path $Path))
	{ Write-Error "The path '$Path' does not exist."; return 
	}
	$item = Get-Item -Path $Path
	if ($item.PSIsContainer)
	{ Get-ChildItem -Path $item.FullName 
	} else
	{ Get-Content -Path $item.FullName 
	}
}

<#
.SYNOPSIS
    Creates a file or directory based on the path, creating parent directories as needed.
.DESCRIPTION
    If the path string ends with a file extension (e.g., '.txt', '.log'), it creates a file.
    Otherwise, it creates a directory. The -Force switch is used internally to ensure that
    the full directory path is created if it does not already exist.
.PARAMETER Path
    The full path for the item you want to create.
.EXAMPLE
    New-SmartItem -Path "C:\Temp\new-project\src\main.js"
    # Creates the 'new-project' and 'src' folders, then creates an empty 'main.js' file.
.EXAMPLE
    New-SmartItem -Path "C:\Temp\another-project\assets"
    # Creates the 'another-project' folder and the 'assets' subfolder.
#>
function New-SmartItem
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	try
	{
		if ([System.IO.Path]::HasExtension($Path))
		{
			# Path looks like a file
			if ($pscmdlet.ShouldProcess($Path, "Create File"))
			{
				New-Item -Path $Path -ItemType File -Force | Out-Null
				Write-Host "Successfully created file: $Path" -ForegroundColor Green
			}
		} else
		{
			# Path looks like a directory
			if ($pscmdlet.ShouldProcess($Path, "Create Directory"))
			{
				New-Item -Path $Path -ItemType Directory -Force | Out-Null
				Write-Host "Successfully created directory: $Path" -ForegroundColor Green
			}
		}
	} catch
	{
		Write-Error "Failed to create item at path '$Path'. Error: $_"
	}
}


# --- Alias Definitions ---
Set-Alias -Name 'jd' -Value 'Join-Directories' -Description 'Alias for Join-Directories'
Set-Alias -Name 'cdd' -Value 'Set-SmartLocation' -Description 'Alias for Set-SmartLocation'
Set-Alias -Name 'lsc' -Value 'Get-SmartContent' -Description 'Alias for Get-SmartContent'
Set-Alias -Name 'nsi' -Value 'New-SmartItem' -Description 'Alias for New-SmartItem' 
Set-Alias -Name 'touch' -Value 'New-SmartItem' -Description 'Alias for New-SmartItem'


Export-ModuleMember -Function 'Join-Directories', 'Set-SmartLocation', 'Get-SmartContent', 'New-SmartItem' -Alias 'jd', 'cdd', 'lsc', 'nsi', 'touch'
