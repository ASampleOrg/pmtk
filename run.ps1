[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ConfigFilePath,
    [Parameter()]
    [String]
    $WorkingDirectory
)


# Import the local module
Import-Module -Name $PSScriptRoot/pmtk-module/pmtk.psm1

$config = Get-CsvConfig -filePath $ConfigFilePath

Write-Output "Config file loaded: $ConfigFilePath"
Write-Output "Config values:"
$config | Format-Table

# for each row in the config file create a new issue sync run

New-IssueSyncRun -ConfigData $config -WorkingDirectory $WorkingDirectory
