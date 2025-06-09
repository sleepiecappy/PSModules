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

<#
.SYNOPSIS
    Launches a command and provides a powerful, interactive TUI to view, filter,
    search, and interact with its output in real-time.
.DESCRIPTION
    Trace-CommandOutput starts a specified process and captures its standard output and
    error streams. It displays the output in a scrollable window with a status bar

    This function can be called in two ways:
    1. By providing the executable and its arguments separately (-FilePath, -ArgumentList).
    2. By providing the entire command as a single string (-Command).

    MODES:
      - Filter (Default): Keystrokes update a live regex filter.
      - Interactive: Keystrokes are sent to the process's standard input.
      - Search: Keystrokes search the entire output buffer.

    HOTKEYS:
      - Ctrl+F: Enter Filter mode.
      - Ctrl+I: Enter Interactive mode.
      - Ctrl+S: Enter Search mode.
      - Ctrl+C: Terminate the running process and exit.
      - ESC: Clear current filter/search or exit the current mode.
      - Up/Down Arrows: Scroll through output.
.PARAMETER FilePath
    The path to the executable file to run. Used with -ArgumentList.
.PARAMETER ArgumentList
    A string or array of strings specifying the arguments for the executable. Used with -FilePath.
.PARAMETER Command
    A single string representing the entire command to execute, including arguments.
.PARAMETER InputObject
    Accepts piped input for basic, non-interactive filtering.
.EXAMPLE
    Trace-CommandOutput -Command "dotnet run --project ./src/MyApi --no-build"
    Launches the specified dotnet command inside the interactive tracer.
.EXAMPLE
    Trace-CommandOutput -FilePath "ping" -ArgumentList "google.com", "-t"
    Traces a continuous ping, allowing you to filter for "Reply" or "Timeout" as it runs.
.EXAMPLE
    Start-Project
    (Recommended) Automatically uses this tracer for projects.
#>
function Trace-CommandOutput {
	[CmdletBinding(DefaultParameterSetName = 'Exec_Individual')]
	param(
		[Parameter(ParameterSetName = 'Exec_Individual', Mandatory = $true)]
		[string]$FilePath,

		[Parameter(ParameterSetName = 'Exec_Individual')]
		[string[]]$ArgumentList,

		[Parameter(ParameterSetName = 'Exec_Command', Mandatory = $true)]
		[string]$Command,

		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipe')]
		$InputObject
	)

	# --- Parameter Handling ---
	if ($pscmdlet.ParameterSetName -eq 'Pipe') {
		# Simple, non-interactive mode for basic piping
		Write-Output $InputObject
		return
	}

	if ($pscmdlet.ParameterSetName -eq 'Exec_Command') {
		# Parse the single command string into FilePath and ArgumentList
		$parseErrors = [System.Management.Automation.Language.ParseError[]]@()
		$tokens = [System.Management.Automation.Language.Parser]::Tokenize($Command, [ref]$parseErrors)
		if ($parseErrors.Count -gt 0) {
			Write-Error "Failed to parse the command string: $($parseErrors[0].Message)"
			return
		}
		$FilePath = $tokens[0].Content
		$ArgumentList = $tokens[1..($tokens.Count - 1)].Content
	}
	# --- End Parameter Handling ---


	$process = New-Object System.Diagnostics.Process
	$process.StartInfo.FileName = $FilePath
	$process.StartInfo.Arguments = $ArgumentList -join ' '
	$process.StartInfo.UseShellExecute = $false
	$process.StartInfo.RedirectStandardOutput = $true
	$process.StartInfo.RedirectStandardError = $true
	$process.StartInfo.RedirectStandardInput = $true
	$process.StartInfo.CreateNoWindow = $true

	$outputBuffer = [System.Collections.Generic.List[string]]::new()
	$filteredBuffer = [System.Collections.Generic.List[string]]::new()
	$sync = [System.Object]::new()

	$mode = "Filter" # Modes: Filter, Interactive, Search
	$filterText = ""
	$searchText = ""
	$scrollTop = 0
	$exitRequest = $false

	$outputHandler = {
		param($sender, $e)
		if ($null -ne $e.Data) {
			$line = "[$(Get-Date -Format 'HH:mm:ss')] $($e.Data)"
			lock ($sync) {
				$outputBuffer.Add($line)
			}
		}
	}

	$process.OutputDataReceived.Add($outputHandler)
	$process.ErrorDataReceived.Add($outputHandler)

	try {
		Clear-Host
		$process.Start() | Out-Null
		$process.BeginOutputReadLine()
		$process.BeginErrorReadLine()

		while (-not $process.HasExited -and -not $exitRequest) {
			# Redraw UI
			lock ($sync) {
				if ($mode -eq "Filter") {
					$newFiltered = $outputBuffer | Where-Object { $_ -match $filterText }
					$filteredBuffer.Clear()
					$filteredBuffer.AddRange($newFiltered)
				}
				elseif ($mode -eq "Search") {
					$newFiltered = $outputBuffer | Where-Object { $_ -match $searchText }
					$filteredBuffer.Clear()
					$filteredBuffer.AddRange($newFiltered)
				}
				else {
					# Interactive
					$filteredBuffer.Clear()
					$filteredBuffer.AddRange($outputBuffer)
				}
			}
			Draw-UI
			Process-Keystroke
		}

	}
	finally {
		if (-not $process.HasExited) {
			$process.Kill()
		}
		$process.Dispose()
		Clear-Host
		Write-Host "--- Process terminated. Final Output (unfiltered): ---" -ForegroundColor Yellow
		$outputBuffer | Write-Output
	}

	function Draw-UI {
		$width = $Host.UI.RawUI.WindowSize.Width
		$height = $Host.UI.RawUI.WindowSize.Height
		$viewHeight = $height - 2

		# Status Bar
		$status = " MODE: $($mode.ToUpper()) | Filter: $filterText | Search: $searchText | Lines: $($outputBuffer.Count) "
		$statusLine = $status.PadRight($width)
		Write-Host -Object $statusLine -BackgroundColor White -ForegroundColor Black -NoNewline
		$Host.UI.RawUI.CursorPosition = @{X = 0; Y = 0 }


		# Main Content
		$maxScroll = [Math]::Max(0, $filteredBuffer.Count - $viewHeight)
		$scrollTop = [Math]::Min($scrollTop, $maxScroll)
		$scrollTop = [Math]::Max(0, $scrollTop)

		$displayLines = $filteredBuffer | Select-Object -Skip $scrollTop -First $viewHeight
		for ($i = 0; $i -lt $viewHeight; $i++) {
			$line = if ($i -lt $displayLines.Count) { $displayLines[$i] } else { "" }
			$line = $line.PadRight($width)
			if ($line.Length -gt $width) { $line = $line.Substring(0, $width) }
			Write-Host -Object $line
		}

		# Footer/Help Bar
		$help = " [Ctrl+F] Filter | [Ctrl+I] Interactive | [Ctrl+S] Search | [Ctrl+C] Exit "
		$helpLine = $help.PadRight($width)
		$Host.UI.RawUI.CursorPosition = @{X = 0; Y = ($height - 1) }
		Write-Host -Object $helpLine -BackgroundColor Gray -ForegroundColor White -NoNewline

		# Reset cursor for typing
		$cursorX = if ($mode -eq "Filter") { 17 + $filterText.Length } `
			elseif ($mode -eq "Search") { 30 + $searchText.Length } `
			else { 0 }
		$Host.UI.RawUI.CursorPosition = @{X = $cursorX; Y = 0 }
	}

	function Process-Keystroke {
		if (-not $Host.UI.RawUI.KeyAvailable) { Start-Sleep -Milliseconds 50; return }
		$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

		# Global Hotkeys
		if ($key.Control) {
			switch ($key.Character) {
				'f' { $mode = "Filter"; $searchText = ""; return }
				'i' { $mode = "Interactive"; $filterText = ""; $searchText = ""; return }
				's' { $mode = "Search"; $filterText = ""; return }
				'c' { $exitRequest = $true; return }
			}
		}

		switch ($key.VirtualKeyCode) {
			38 {
				# Up Arrow
				$scrollTop = [Math]::Max(0, $scrollTop - 1)
				return
			}
			40 {
				# Down Arrow
				$scrollTop = [Math]::Min($filteredBuffer.Count - 1, $scrollTop + 1)
				return
			}
		}


		if ($mode -eq "Filter") {
			Handle-TextInput -key $key -textRef ([ref]$filterText)
		}
		elseif ($mode -eq "Search") {
			Handle-TextInput -key $key -textRef ([ref]$searchText)
		}
		elseif ($mode -eq "Interactive") {
			# Pass key directly to process stdin
			$process.StandardInput.Write($key.Character)
		}
	}

	function Handle-TextInput {
		param([System.Management.Automation.Host.KeyInfo]$key, [ref]$textRef)
		switch ($key.VirtualKeyCode) {
			27 { $textRef.Value = "" } # Escape
			8 {
				# Backspace
				if ($textRef.Value.Length -gt 0) {
					$textRef.Value = $textRef.Value.Substring(0, $textRef.Value.Length - 1)
				}
			}
			default {
				if ($key.Character -ne 0) {
					$textRef.Value += $key.Character
				}
			}
		}
	}
}


function Get-ProjectContext {
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
	while ($currentPath -ne $null) {
		foreach ($type in $projectMarkers.Keys) {
			$markers = $projectMarkers[$type]
			if (Get-ChildItem -Path $currentPath.FullName -Filter $markers -ErrorAction SilentlyContinue | Select-Object -First 1) {
				Write-Verbose "Detected project type '$type' in $($currentPath.FullName)"
				return [PSCustomObject]@{
					Type = $type
					Name = $currentPath.Name
					Root = $currentPath.FullName
				}
			}
		}
		$currentPath = $currentPath.Parent
	}
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
function Sync-ProjectIndex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[string]$Path = $HOME
	)

	if (-not (Test-Path -Path $global:ProjectProfilesPath)) {
		Write-Verbose "Creating project profiles directory at $($global:ProjectProfilesPath)"
		New-Item -Path $global:ProjectProfilesPath -ItemType Directory | Out-Null
	}

	Write-Host "Searching for projects in '$Path' to sync..."
	$projects = Get-ChildItem -Path $Path -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object {
		Test-Path -Path (Join-Path $_.FullName ".git") -PathType Container
	}

	foreach ($project in $projects) {
		$profileName = "$($project.Name).ps1"
		$profilePath = Join-Path -Path $global:ProjectProfilesPath -ChildPath $profileName

		if (-not (Test-Path $profilePath)) {
			if ($pscmdlet.ShouldProcess($profilePath, "Create project configuration file")) {
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
function Edit-ProjectConfig {
	[CmdletBinding()]
	param()

	$context = Get-ProjectContext
	if ($null -eq $context) {
		Write-Error "No project context found. Navigate to a project directory first."
		return
	}

	$profileName = "$($context.Name).ps1"
	$profilePath = Join-Path -Path $global:ProjectProfilesPath -ChildPath $profileName

	if (-not (Test-Path -Path $profilePath)) {
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
function Enter-Project {
	[CmdletBinding()]
	param()

	$indexedProjects = Get-ChildItem -Path $global:ProjectProfilesPath -Filter "*.ps1" | ForEach-Object {
		# Extract the full path from the template file content
		$fullPathLine = Get-Content $_.FullName | Select-Object -First 5 | Where-Object { $_ -match "^# Full Path: " }
		$projectPath = $fullPathLine -replace "^# Full Path: ", ""

		if (Test-Path $projectPath) {
			[PSCustomObject]@{
				Name    = $_.BaseName
				Path    = $projectPath
				Profile = $_.FullName
			}
		}
	}

	if ($null -eq $indexedProjects) {
		Write-Warning "No projects indexed. Run Sync-ProjectIndex first."
		return
	}

	$selectedProject = $indexedProjects | Out-GridView -Title "Enter a project" -PassThru

	if ($null -ne $selectedProject) {
		Write-Host "Entering project '$($selectedProject.Name)'..." -ForegroundColor Green
		Set-Location -Path $selectedProject.Path

		Write-Host "Loading project environment from '$($selectedProject.Profile)'..."
		# Dot source the script to load its contents into the current scope
		. $selectedProject.Profile
	}
}

<#
.SYNOPSIS
    Builds the project, using custom actions if defined.
#>
function Invoke-ProjectBuild {
	[CmdletBinding()]
	param([switch]$Release)

	# Check for a custom override function first
	if (Get-Command 'Invoke-Build' -ErrorAction SilentlyContinue) {
		Invoke-Build @PSBoundParameters
		return
	}

	$context = Get-ProjectContext
	if ($null -eq $context) { Write-Error "No project type detected."; return }
	Set-Location -Path $context.Root
	# Fallback to auto-detection
	switch ($context.Type) {
		"Node" { npm run build }
		"Rust" { if ($Release) { cargo build --release } else { cargo build } }
		".NET" { if ($Release) { dotnet build -c Release } else { dotnet build } }
		"Maven" { mvn clean package }
		default { Write-Warning "No build command defined for '$($context.Type)'." }
	}
}

<#
.SYNOPSIS
    Runs the project, using custom actions if defined.
#>
function Start-Project {
	[CmdletBinding()]
	param(
		[switch]$Watch,
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$PassthroughArgs
	)

	# Check for a custom override function first
	if (Get-Command 'Start-App' -ErrorAction SilentlyContinue) {
		Start-App @PSBoundParameters
		return
	}

	$context = Get-ProjectContext
	if ($null -eq $context) { Write-Error "No project type detected."; return }
	Set-Location -Path $context.Root
	$argsString = $PassthroughArgs -join " "
	# Fallback to auto-detection
	switch ($context.Type) {
		"Node" { if ($Watch) { npm run dev -- $argsString } else { npm start -- $argsString } }
		"Rust" { if ($Watch) { cargo watch -x run -- $argsString } else { cargo run -- $argsString } }
		".NET" { if ($Watch) { dotnet watch run -- $argsString } else { dotnet run -- $argsString } }
		default { Write-Warning "No start command defined for '$($context.Type)'." }
	}
}

Export-ModuleMember -Function 'Sync-ProjectIndex', 'Edit-ProjectConfig', 'Enter-Project', 'Invoke-ProjectBuild', 'Start-Project', 'Trace-CommandOutput'
