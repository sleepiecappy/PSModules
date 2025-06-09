@{

    RootModule = 'GitTrunkHelpers.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-1122-3344-5566-7890abcdef12' # New unique GUID

    Description = 'A set of helper functions to streamline a Trunk-Based Development workflow in Git.'

    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Start-GitFeature',
        'Sync-GitFeature',
        'Complete-GitFeature',
        'Cleanup-GitBranches'
    )

    AliasesToExport = @(
        'sgf',
        'syncf',
        'cgf',
        'cleanup'
    )

    CmdletsToExport = @()
    VariablesToExport = @()

    PrivateData = @{
        PSData = @{
            Tags = @('Git', 'Trunk-Based', 'Development', 'Workflow', 'VersionControl')
        }
    }

}
