<#
.SYNOPSIS
    A PowerShell module to easily manage, create, and launch Android emulators (AVDs).
.DESCRIPTION
    This module simplifies managing Android emulators by providing interactive
    prompts to create new devices, select from a list of available devices, and

    choose whether to perform a cold boot.
#>
[CmdletBinding()]
param()

#------------------------------------------------------------------------------------------------
# Private Helper Functions
#------------------------------------------------------------------------------------------------

function Get-AndroidSdkToolPath {
    <#
    .SYNOPSIS
        (Internal) Finds the full path to a specific tool in the Android SDK.
    .PARAMETER ToolName
        The name of the tool executable (e.g., 'emulator.exe', 'avdmanager.bat').
    #>
    param(
        [string]$ToolName
    )

    $sdkRoot = $env:ANDROID_SDK_ROOT
    if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
        $sdkRoot = $env:ANDROID_HOME
    }

    if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
        Write-Error "Android SDK path not found. Please set the 'ANDROID_SDK_ROOT' or 'ANDROID_HOME' environment variable."
        return $null
    }

    # Common paths for the tools
    $possiblePaths = @(
        (Join-Path -Path $sdkRoot -ChildPath "emulator\$ToolName"),
        (Join-Path -Path $sdkRoot -ChildPath "cmdline-tools\latest\bin\$ToolName"),
        (Join-Path -Path $sdkRoot -ChildPath "tools\bin\$ToolName")
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path -PathType Leaf) {
            return $path
        }
    }

    Write-Error "$ToolName not found. Please ensure the Android SDK Command-line Tools are installed and the SDK path is correct."
    return $null
}

#------------------------------------------------------------------------------------------------
# Public Functions
#------------------------------------------------------------------------------------------------

<#
.SYNOPSIS
    Starts an Android emulator from a list of available devices.
.DESCRIPTION
    This function retrieves a list of all configured Android Virtual Devices (AVDs),
    displays them in a filterable grid view for selection, and then prompts the user
    whether to start the emulator with a cold boot (no snapshot).
.EXAMPLE
    Start-AndroidEmulator
    # An interactive window will appear to select an emulator.
#>
function Start-AndroidEmulator {
    [CmdletBinding()]
    param()

    $emulatorCli = Get-AndroidSdkToolPath -ToolName "emulator.exe"
    if ($null -eq $emulatorCli) {
        return 
    }

    Write-Host "Searching for available Android emulators (AVDs)..."
    $avds = & $emulatorCli -list-avds
    if ($avds.Count -eq 0) {
        Write-Error "No Android Virtual Devices (AVDs) found. Please create one using 'New-AndroidEmulator'."
        return
    }

    Write-Host "Please select an emulator to start."
    $selectedAvd = $avds | Out-GridView -Title "Select an Android Emulator" -OutputMode Single

    if ($null -eq $selectedAvd) {
        Write-Host "Operation cancelled. No emulator selected." -ForegroundColor Yellow
        return
    }

    $coldBootChoice = Read-Host -Prompt "Start with a cold boot (y/n)? [default: n]"
    $startArgs = @("-avd", $selectedAvd)

    if ($coldBootChoice -eq 'y') {
        Write-Host "Starting emulator '$selectedAvd' with a cold boot..." -ForegroundColor Cyan
        $startArgs += "-no-snapshot-load"
    }
    else {
        Write-Host "Starting emulator '$selectedAvd'..." -ForegroundColor Cyan
    }

    Start-Process -FilePath $emulatorCli -ArgumentList $startArgs
}


<#
.SYNOPSIS
    Creates a new Android Virtual Device (AVD).
.DESCRIPTION
    This function interactively guides you through creating a new AVD. It fetches a list
    of all installed system images, lets you choose one, and prompts for a name for the
    new emulator. It then uses 'avdmanager' to create the device.
.EXAMPLE
    New-AndroidEmulator
    # An interactive process will begin to create a new emulator.
#>
function New-AndroidEmulator {
    [CmdletBinding()]
    param()

    $avdManagerCli = Get-AndroidSdkToolPath -ToolName "avdmanager.bat"
    if ($null -eq $avdManagerCli) {
        return 
    }

    Write-Host "Fetching available system images..."
    # The `sdkmanager` is used to get a clean list of installed package paths
    $sdkManagerCli = Get-AndroidSdkToolPath -ToolName "sdkmanager.bat"
    if ($null -eq $sdkManagerCli) {
        return 
    }

    $installedPackages = & $sdkManagerCli --list_installed | Select-String -Pattern "system-images;"
    if ($installedPackages.Count -eq 0) {
        Write-Error "No system images found. Please install a system image using the SDK Manager in Android Studio."
        return
    }

    $systemImages = $installedPackages | ForEach-Object { $_.Line.Split(' ')[0] }

    Write-Host "Please select a system image for the new emulator."
    $selectedImage = $systemImages | Out-GridView -Title "Select a System Image" -OutputMode Single

    if ([string]::IsNullOrWhiteSpace($selectedImage)) {
        Write-Host "Operation cancelled. No system image selected." -ForegroundColor Yellow
        return
    }

    $avdName = Read-Host -Prompt "Enter a name for the new emulator (e.g., Pixel_6_API_33)"
    if ([string]::IsNullOrWhiteSpace($avdName)) {
        Write-Error "AVD name cannot be empty."
        return
    }
    # Sanitize name to be safe for command line
    $avdName = $avdName -replace '[^a-zA-Z0-9_.-]', '_'


    Write-Host "Creating AVD '$avdName' with image '$selectedImage'..." -ForegroundColor Green
    # Use 'echo "no"' to automatically answer the prompt for creating a custom hardware profile.
    echo "no" | & $avdManagerCli create avd --force --name $avdName --package $selectedImage

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ AVD '$avdName' created successfully." -ForegroundColor Green
    }
    else {
        Write-Error "Failed to create AVD. Please check the output above for errors."
    }
}


# --- Alias Definitions ---
Set-Alias -Name 'sae' -Value 'Start-AndroidEmulator' -Description 'Alias for Start-AndroidEmulator'
Set-Alias -Name 'nae' -Value 'New-AndroidEmulator' -Description 'Alias for New-AndroidEmulator'

Export-ModuleMember -Function 'Start-AndroidEmulator', 'New-AndroidEmulator' -Alias 'sae', 'nae'
