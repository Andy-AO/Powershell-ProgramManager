﻿# Create some global variables
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile -Path "$($script:ModuleRoot)\ProgramManager.psd1").ModuleVersion

# Detect whether at some level dotsourcing was enforced
$script:doDotSource = $global:ModuleDebugDotSource
if ($ProgramManager_dotsourcemodule) { $script:doDotSource = $true }

# Detect whether at some level loading individual module files, rather than the compiled module was enforced
$importIndividualFiles = $global:ModuleDebugIndividualFiles
if ($ProgramManager_importIndividualFiles) { $importIndividualFiles = $true }

# Resolve-Path function which deals with non-existent paths
function Resolve-Path_i {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string]
		$Path # Path to resolve
	)
	
	# Run the command silently
	$resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
	
	# Variable will be null if $Path doesn't exist
	# In that case set it to an empty string
	if ($null -eq $resolvedPath) {
		$resolvedPath = ""
	}
	
	$resolvedPath
}

if (Test-Path (Resolve-Path_i -Path "$($script:ModuleRoot)\..\.git")) { $importIndividualFiles = $true }
if ("<was not compiled>" -eq '<was not compiled>') { $importIndividualFiles = $true }

# Imports a module file, either through dot-sourcing or through invoking the script
function Import-ModuleFile {
	<#
		.SYNOPSIS
			Loads files into the module on module import.
		
		.DESCRIPTION
			This helper function is used during module initialization.
			It should always be dotsourced itself, in order to proper function.
			
			This provides a central location to react to files being imported, if later desired
		
		.PARAMETER Path
			The path to the file to load
		
		.EXAMPLE
			PS C:\> . Import-ModuleFile -File $function.FullName
	
			Imports the file stored in $function according to import policy
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Path # Path of module file
	)
	
	#Get the resolved path to avoid any cross-OS issues
	$resolvedPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($Path).ProviderPath
	if ($doDotSource) {
		. $resolvedPath 
	}else {
		$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($resolvedPath))), $null, $null) 
	}
}

#region Load individual files
if ($importIndividualFiles) {
	# Execute Preimport actions
	. Import-ModuleFile -Path "$ModuleRoot\internal\scripts\preimport.ps1"
	
	# Import all internal functions
	foreach ($function in (Get-ChildItem "$ModuleRoot\internal\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {				
		. Import-ModuleFile -Path $function.FullName
	}
	
	# Import all public functions
	foreach ($function in (Get-ChildItem "$ModuleRoot\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {		
		. Import-ModuleFile -Path $function.FullName
	}
	
	# Execute Postimport actions
	. Import-ModuleFile -Path "$ModuleRoot\internal\scripts\postimport.ps1"
	
	# End it here, do not load compiled code below
	return
}
#endregion Load individual files

#region Load compiled code
"<compile code into here>"
#endregion Load compiled code