﻿Describe -Verbose "Validating Add-PMProgram" {
    $VerbosePreference = "Continue"
    
    # Create a temporary data directory within the Pester temp drive
    # Modify the module datapath to reflect this temporary location
    New-Item -ItemType Directory -Path "TestDrive:\ProgramManager\"
    & (Get-Module ProgramManager) { $script:DataPath = "TestDrive:\ProgramManager" }
    # For use within the test script, since no access to module- $script:DataPath
    $dataPath = "TestDrive:\ProgramManager"
        
    Write-Verbose "TestDrive is: $((Get-PSDrive TestDrive).Root)"
    Write-Verbose "DataPath is: $($dataPath)"
        
    Context "Local Package Validation" {
        
        It "Given valid parameters: Extension .<Extension>; Path TestDrive:\RawPackages\<FileName>; InstallDir <InstallDir>; Note <Note>; It should correctly write the data" -TestCases @(
            
            # The different valid test cases for a local package (exe and msi)
            @{ Extension = "exe"; FileName = "localpackage-1.0.exe"; InstallDir = ""; Note = "" }
            @{ Extension = "exe"; FileName = "localpackage-1.0.exe"; InstallDir = "TestDrive:\"; Note = "" }
            @{ Extension = "exe"; FileName = "localpackage-1.0.exe"; InstallDir = ""; Note = "A descriptive note" }
            @{ Extension = "exe"; FileName = "localpackage-1.0.exe"; InstallDir = "TestDrive:\"; Note = "A descriptive note" }
            @{ Extension = "msi"; FileName = "localpackage-1.0.msi"; InstallDir = ""; Note = "" }
            @{ Extension = "msi"; FileName = "localpackage-1.0.msi"; InstallDir = "TestDrive:\"; Note = "" }
            @{ Extension = "msi"; FileName = "localpackage-1.0.msi"; InstallDir = ""; Note = "A descriptive note" }
            @{ Extension = "msi"; FileName = "localpackage-1.0.msi"; InstallDir = "TestDrive:\"; Note = "A descriptive note" }
            
        ) {
            
            # Pass test case data into the test body
            Param ($Extension, $FileName, [AllowEmptyString()]$InstallDir, [AllowEmptyString()]$Note)
            
            
            # Copy the test packages from the git repo to the temporary drive
            New-Item -ItemType Directory -Path "TestDrive:\RawPackages\"
            Copy-Item -Path "$PSScriptRoot\..\files\packages\*" -Destination "TestDrive:\RawPackages\"
                        
            # Run the command
            Add-PMProgram -Name "test-package" -LocalPackage -PackageLocation "TestDrive:\RawPackages\$FileName" -InstallDirectory $InstallDir -Note $Note -Verbose
            
            # Read the written data back in to validate
            $packageList = Import-PackageList
            $package = $packageList[0]
            $packageList.Count | Should -Be 1
            
            # Check the property values are correct
            $package.Name | Should -Be "test-package"
            $package.Type | Should -Be "LocalPackage"
            $package.IsInstalled | Should -Be $false
            $package.ExecutableName | Should -Be $FileName
            $package.ExecutableType | Should -Be ".$Extension"
            
            # Check the optional property valuse are correct
            if ([System.String]::IsNullOrWhiteSpace($InstallDir) -eq $true) {
                $package.InstallDirectory | Should -Be $null
            }else {
                $package.InstallDirectory | Should -Be $InstallDir
            }
            
            if ([System.String]::IsNullOrWhiteSpace($Note) -eq $true) {
                $package.Note | Should -Be $null
            }else {
                $package.Note | Should -Be $Note
            }
            
            # Test that there is only one package in the store
            $packageFiles = Get-ChildItem -Path "$dataPath\packages\"            
            $packageFiles.Count | Should -Be 1
            
            # Check that the executable hasn't been left behind in its original directory
            (Test-Path -Path "TestDrive:\RawPackages\$FileName") | Should -Be $false
            
            # Check that the executable has been correctly moved over
            (Test-Path -Path "$dataPath\packages\test-package\$($package.ExecutableName)") | Should -Be $true
            
            
            # Delete the package store and database file for next test
            Remove-Item -Path "$dataPath\packageDatabase.xml" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$dataPath\packages" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "TestDrive:\RawPackages" -Recurse -Force -ErrorAction SilentlyContinue
            
        }
        <#
        It "Given invalid parameter -Path" -TestCases @(
           
            @{ Path = "" }
        
        ) {
            
            # Pass test case data into the test body
            Param ($Path)
            
            
        }#>
        
        # Delete the package store and database file for next set of tests
        Remove-Item -Path "$dataPath\packageDatabase.xml" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$dataPath\packages" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "TestDrive:\RawPackages" -Recurse -Force -ErrorAction SilentlyContinue
        
        
    }
    
    <#
    Context "Url Package Validation" {
        
    }
    
    Context "Chocolatey Package Validation" {
        
    }#>
    
}