This module provides convenient, interactive functions to manage your Android Virtual Devices (AVDs) directly from the PowerShell terminal.

## Prerequisites
Before using this module, please ensure you have the following set up:

Android SDK: You must have the Android SDK installed on your system.

Environment Variable: The ANDROID_SDK_ROOT (or the older ANDROID_HOME) environment variable must be set and point to the location of your SDK. The module uses this to find the necessary command-line tools.

Command-line Tools: You must have the "Android SDK Command-line Tools" installed via the SDK Manager in Android Studio. This provides the avdmanager.bat and sdkmanager.bat files required by this module.

## Installation
Find one of your PowerShell module paths by running $env:PSModulePath -split ';'. A good user-specific location is typically ~\Documents\PowerShell\Modules\.

Create a new folder named AndroidEmulatorManager Inside your chosen modules directory.

Save the AndroidEmulatorManager.psm1 and AndroidEmulatorManager.psd1 files inside this new AndroidEmulatorManager folder.

Open a new PowerShell terminal. The functions and aliases will be automatically available.

## Commands
### Create a New Emulator
|

| Command | Alias | Description |
| New-AndroidEmulator | nae | Interactively guides you to create a new AVD. |

## Start an Emulator
| Command | Alias | Description |
| Start-AndroidEmulator | sae | Interactively starts an existing AVD. |

