#
# Module manifest for module 'ProjectDevTools'


@{

	RootModule        = 'ProjectDevTools.psm1'
	ModuleVersion     = '3.2.0' # Updated version
	GUID              = 'f0e1d2c3-b4a5-6789-0123-abcdef456789'
	PowerShellVersion = '5.1'
	
	FunctionsToExport = @(
		'Sync-ProjectIndex',
		'Edit-ProjectConfig',
		'Enter-Project',
		'Invoke-ProjectBuild',
		'Start-Project',
		'Trace-CommandOutput'
	)
	
	AliasesToExport   = @(
		'tco',
		'trace',
		'sp',
		'ipb',
		'ep',
		'epc',
		'spi'
	)
	
	
	CmdletsToExport   = @()
	VariablesToExport = @()
	
	PrivateData       = @{
		PSData = @{
			Tags = @('Project', 'DevTools', 'Build', 'Run', 'Log', 'Filter', 'Trace', 'Interactive', 'TUI', 'Alias')
		}
	}
	
}
	