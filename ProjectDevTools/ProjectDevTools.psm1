#Requires -Version 5.1
#Requires -Modules PowerShellGet


<#
.SYNOPSIS
    A suite of context-aware development tools for a terminal-first workflow,
    now with project-specific configuration profiles.

.DESCRIPTION
    ProjectDevTools provides functions that automatically detect project types and offer
    unified commands for building and running. Version 2 adds a project indexing
    system that allows you to define and load project-specific environment variables,
    aliases, and functions from configuration scripts stored in ~/.project_profiles.
#>

#------------------------------------------------------------------------------------------------
# Module Configuration
#------------------------------------------------------------------------------------------------

$global:ProjectProfilesPath = Join-Path -Path $HOME -ChildPath ".project_profiles"


function Get-ProjectContext
{
	<# .SYNOPSIS (Internal) Detects the project type. #>
	[CmdletBinding()]
	param([string]$Path = $PWD)

	$projectMarkers = @{
		"Node"   = "package.json";
		"Rust"   = "Cargo.toml";
		".NET"   = "*.csproj", "*.fsproj", "*.sln";
		"Python" = "pyproject.toml", "requirements.txt";
		"Maven"  = "pom.xml";
	}

	$currentPath = Get-Item -Path $Path
	while ($null -ne $currentPath)
	{
		foreach ($type in $projectMarkers.Keys)
		{
			$markers = $projectMarkers[$type]
			foreach ($marker in $markers)
			{	
				if (Get-ChildItem -Path $currentPath.FullName -Filter $marker -ErrorAction SilentlyContinue | Select-Object -First 1)
				{
					Write-Verbose "Detected project type '$type' in $($currentPath.FullName)"
					return [PSCustomObject]@{
						Type = $type
						Name = $currentPath.Name
						Root = $currentPath.FullName
					}
				}
			}
		}
		$currentPath = $currentPath.Parent
	}
	Write-Verbose "No known project type detected in $Path"
	return $null
}

#------------------------------------------------------------------------------------------------
# Public Functions
#------------------------------------------------------------------------------------------------

<#
.SYNOPSIS
    Scans for Git projects and creates their initial configuration files.
.DESCRIPTION
    Recursively searches a root path for Git repositories. For each project found,
    it ensures a corresponding configuration script (.ps1) exists in the central
    profile directory (~/.project_profiles). If a profile doesn't exist, it creates
    one with helpful boilerplate comments.
.PARAMETER Path
    The root directory to scan for projects. Defaults to $HOME.
.EXAMPLE
    Sync-ProjectIndex -Path "D:\source"
    Scans all folders under D:\source and creates config files for any Git projects found.
#>
function Sync-ProjectIndex
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[string]$Path = $HOME
	)

	if (-not (Test-Path -Path $global:ProjectProfilesPath))
	{
		Write-Verbose "Creating project profiles directory at $($global:ProjectProfilesPath)"
		New-Item -Path $global:ProjectProfilesPath -ItemType Directory | Out-Null
	}

	Write-Host "Searching for projects in '$Path' to sync..."
	$projects = Get-ChildItem -Path $Path -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object {
		Test-Path -Path (Join-Path $_.FullName ".git") -PathType Container
	}

	foreach ($project in $projects)
	{
		$profileName = "$($project.Name).ps1"
		$profilePath = Join-Path -Path $global:ProjectProfilesPath -ChildPath $profileName

		if (-not (Test-Path $profilePath))
		{
			if ($pscmdlet.ShouldProcess($profilePath, "Create project configuration file"))
			{
				Write-Host "Creating profile for '$($project.Name)'..." -ForegroundColor Green
				$template = @"
# Configuration for project: $($project.Name)
# This file is loaded automatically by Enter-Project.
# Full Path: $($project.FullName)

# --- Environment Variables ---
# Example: Set an API key or database connection string.
# $env:MY_API_KEY = '12345-ABCDE'
# $env:DATABASE_URL = 'postgres://user:pass@localhost/mydb'

# --- Aliases ---
# Create temporary aliases available only in this project's context.
# Example: A shortcut for a common command.
# Set-Alias -Name "t" -Value "task"
# Set-Alias -Name "dcup" -Value "docker-compose up -d"

# --- Custom Functions ---
# Define project-specific helper functions.
# Example: A function to quickly connect to the project's test database.
# function Connect-TestDb {
#     psql -U myuser -d my_test_db
# }

# --- Custom Build/Run Actions (Optional Overrides) ---
# Uncomment to override the default behavior of Invoke-ProjectBuild or Start-Project.
# function Invoke-Build {
#     Write-Host "Running CUSTOM build command for $($project.Name)..." -ForegroundColor Yellow
#     # ./my_custom_build_script.sh
# }
#
# function Start-App {
#     Write-Host "Running CUSTOM start command for $($project.Name)..." -ForegroundColor Yellow
#     # ./my_custom_run_script.sh --with-args
# }

Write-Host "Welcome to project '$($project.Name)'" -ForegroundColor Cyan
"@
				$template | Set-Content -Path $profilePath
			}
		}
	}
	Write-Host "Project index sync complete."
}

<#
.SYNOPSIS
    Opens the configuration file for the current project.
.DESCRIPTION
    Finds the active project context and opens its corresponding .ps1
    configuration file from ~/.project_profiles in Neovim.
.EXAMPLE
    Edit-ProjectConfig
#>
function Edit-ProjectConfig
{
	[CmdletBinding()]
	param()

	$context = Get-ProjectContext
	if ($null -eq $context)
	{
		Write-Error "No project context found. Navigate to a project directory first."
		return
	}

	$profileName = "$($context.Name).ps1"
	$profilePath = Join-Path -Path $global:ProjectProfilesPath -ChildPath $profileName

	if (-not (Test-Path -Path $profilePath))
	{
		Write-Warning "No config profile found for '$($context.Name)'. Run Sync-ProjectIndex to create it."
		return
	}

	Write-Host "Opening config for '$($context.Name)'..."
	nvim $profilePath
}

<#
.SYNOPSIS
    Navigates to a project and loads its environment configuration.
.DESCRIPTION
    Displays a filterable list of all indexed projects. Upon selection, it
    changes the directory to the project's root and then loads its corresponding
    configuration script, activating any defined aliases, environment variables,
    and functions for the current session.
.EXAMPLE
    Enter-Project
#>
function Enter-Project
{
	[CmdletBinding()]
	param([switch]$UsePwd)


	$indexedProjects = Get-ChildItem -Path $global:ProjectProfilesPath -Filter "*.ps1" | ForEach-Object {
		# Extract the full path from the template file content
		$fullPathLine = Get-Content $_.FullName | Select-Object -First 5 | Where-Object { $_ -match "^# Full Path: " }
		$projectPath = $fullPathLine -replace "^# Full Path: ", ""

		if (Test-Path $projectPath)
		{
			[PSCustomObject]@{
				Name    = $_.BaseName
				Path    = $projectPath
				Profile = $_.FullName
			}
		}
	}

	if ($null -eq $indexedProjects)
	{
		Write-Warning "No projects indexed. Run Sync-ProjectIndex first."
		return
	}

	$selectedProject = ''
	if ($UsePwd)
	{
		$thisProject = Get-Location
		$selectedProject = $indexedProjects | Where-Object { $_.Path -eq $thisProject.Path }
		
	} else
	{
		$selectedProject = $indexedProjects | Out-GridView -Title "Enter a project" -OutputMode Single
	}

	if ($null -ne $selectedProject)
	{
		Write-Host "Entering project '$($selectedProject.Name)'..." -ForegroundColor Green
		Set-Location -Path $selectedProject.Path

		Write-Host "Loading project environment from '$($selectedProject.Profile)'..."
		# Dot source the script to load its contents into the current scope
		. $selectedProject.Profile
	} else
	{
		Write-Host "No Project found" -ForegroundColor Red
	}
}

<#
.SYNOPSIS
    Builds the project, using custom actions if defined.
#>
function Invoke-ProjectBuild
{
	[CmdletBinding()]
	param([switch]$Release)

	# Check for a custom override function first
	if (Get-Command 'Invoke-Build' -ErrorAction SilentlyContinue)
	{
		Invoke-Build @PSBoundParameters
		return
	}

	$context = Get-ProjectContext
	if ($null -eq $context)
	{ Write-Error "No project type detected."; return 
 }
	Set-Location -Path $context.Root
	# Fallback to auto-detection
	switch ($context.Type)
	{
		"Node"
		{ npm run build 
  }
		"Rust"
		{ if ($Release)
   { cargo build --release 
			} else
			{ cargo build 
			} 
  }
		".NET"
		{ if ($Release)
   { dotnet build -c Release 
			} else
			{ dotnet build 
			} 
  }
		"Maven"
		{ mvn clean package 
  }
		default
		{ Write-Warning "No build command defined for '$($context.Type)'." 
  }
	}
}

<#
.SYNOPSIS
    Runs the project, using custom actions if defined.
#>
function Start-Project
{
	[CmdletBinding()]
	param(
		[switch]$Watch,
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$PassthroughArgs
	)

	# Check for a custom override function first
	if (Get-Command 'Start-App' -ErrorAction SilentlyContinue)
	{
		Start-App @PSBoundParameters
		return
	}

	$context = Get-ProjectContext
	if ($null -eq $context)
	{ Write-Error "No project type detected."; return 
 }
	Set-Location -Path $context.Root
	$argsString = $PassthroughArgs -join " "
	# Fallback to auto-detection
	switch ($context.Type)
	{
		"Node"
		{ if ($Watch)
			{ npm run dev -- $argsString 
			} else
			{ npm start -- $argsString 
			} 
  }
		"Rust"
		{ if ($Watch)
   { cargo watch -x run -- $argsString 
			} else
			{ cargo run -- $argsString 
			} 
  }
		".NET"
		{ if ($Watch)
			{ dotnet watch run -- $argsString 
			} else
			{ dotnet run -- $argsString 
			} 
  }
		default
		{ Write-Warning "No start command defined for '$($context.Type)'." 
  }
	}
}

Export-ModuleMember -Function 'Sync-ProjectIndex', 'Edit-ProjectConfig', 'Enter-Project', 'Invoke-ProjectBuild', 'Start-Project', 'Trace-CommandOutput'
