
@{

    RootModule = 'AndroidEmulatorManager.psm1'
    ModuleVersion = '1.1.0'
    GUID = 'b2c3d4e5-2233-4455-6677-890abcdef123'

    Description = 'A helper module to simplify creating and launching Android emulators.'

    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Start-AndroidEmulator',
        'New-AndroidEmulator'
    )

    AliasesToExport = @(
        'sae',
        'nae'
    )

    CmdletsToExport = @()
    VariablesToExport = @()

    PrivateData = @{
        PSData = @{
            Tags = @('Android', 'Emulator', 'AVD', 'Mobile', 'Development', 'Scaffold')
        }
    }

}
