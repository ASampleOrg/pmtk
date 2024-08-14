[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $FilePath
)

Write-Output "Running Pester tests for $FilePath"