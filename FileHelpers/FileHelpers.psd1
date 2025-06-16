@{

	RootModule        = 'FileHelpers.psm1'
	ModuleVersion     = '1.1.0'
	GUID              = 'd4e5f6a1-4455-6677-8899-abcdef123456'
	
	Description       = 'A collection of helper functions for advanced file and directory manipulation in PowerShell.'
	
	PowerShellVersion = '5.1'
	
	FunctionsToExport = @(
		'Join-Directories',
		'Set-SmartLocation',
		'Get-SmartContent',
		'New-SmartItem'
	)
	
	AliasesToExport   = @(
		'jd',
		'cdd',
		'lsc',
		'nsi',
		'touch'
	)
	
	CmdletsToExport   = @()
	VariablesToExport = @()
	
	PrivateData       = @{
		PSData = @{
			Tags = @('File', 'Directory', 'Manipulation', 'Flatten', 'Helpers', 'Create')
		}
	}
	
}
	
