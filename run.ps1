[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ConfigFilePath
)


# Import the local module
Import-Module -Name $PSScriptRoot/pmtk-module/pmtk.psm1

$config = Get-ConfigAsPSObject -filePath $ConfigFilePath

Write-Output "Config file loaded: $ConfigFilePath"
Write-Output "Config values:"
Write-Output "$(ConvertTo-Json $config)"