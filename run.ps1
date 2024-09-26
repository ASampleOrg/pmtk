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
$config | Format-List

# for each row in the config file create a new issue sync run

New-IssueSyncRun -ConfigData $config -WorkingDirectory $WorkingDirectory

# update the config file to add the burn_down_rate to the burn_total column for each row where include_burn_down is true

Write-Output "Updating config file to add burn_down_rate to burn_total column for each row where include_burn_down is true"
$updatedConfig = $config | ForEach-Object {
    $row = $_
    if ($row.include_burn_down -eq "true") {
        $row.burn_total = $row.burn_total + $row.burn_down_rate
    }
    $row
}

$updatedConfig | Export-Csv -Path $ConfigFilePath -NoTypeInformation
