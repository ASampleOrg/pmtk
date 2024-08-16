function Get-CsvConfig {
    param(
        [string] $filePath
    )

    if (-Not (Test-Path -Path $filePath)) {
        throw "CSV file not found: $filePath"
    }

    $csvContent = Import-Csv -Path $filePath
    return $csvContent
}

function New-IssueSyncRun {
    [CmdletBinding()]
    param (
        [Parameter()]
        [array]
        $ConfigData
    )

    # Get the path above the module directory
    $parentDirectory = Split-Path -Path $PSScriptRoot -Parent


    # for each row in the config file, create a new issue sync run
    foreach ($row in $ConfigData) {
        $customer = $row.customer
        $serviceIssue = $row.service_issue_id
        $serviceIssueRepo = $row.service_issue_repo
        $customerIssue = $row.customer_issue_id
        $customerIssueRepo = $row.customer_issue_repo
    
        # look for a directory with the same name as the customer
        # if it exists get the latest .md file that doesn't end with a _synced suffix in that directory 

        

        Write-Output "Looking for update file for $customer in directory: $parentDirectory"

        $customerDirectory = "$parentDirectory/$customer"
        if (-Not (Test-Path -Path $customerDirectory)) {
            throw "Customer directory not found: $customerDirectory"
        }

        $latestCustomerUpdate = Get-ChildItem -Path $customerDirectory -Filter "*.md" |
        Where-Object { $_.Name -notmatch '_synced\.md$' } |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1

        if ($null -eq $latestCustomerUpdate) {
            throw "No suitable update .md file found in directory: $customerDirectory"
        }

        # using the gh cli create a comment on the service issue and customer issue with the contents of the .md file

        Write-Output "Creating issue sync run for $customer, service issue $serviceIssue, customer issue $customerIssue"
        Write-Output "Using update file: $($latestCustomerUpdate.FullName)"
        $serviceResult = & gh issue comment $serviceIssue -F $($latestCustomerUpdate.FullName) -R $serviceIssueRepo 

        Write-Output "Service result: $serviceResult"

        $customerResult = & gh issue comment $customerIssue -F $($latestCustomerUpdate.FullName) -R $customerIssueRepo

        Write-Output "Customer result: $customerResult"
    }

    # Update the .md file to have a _synced suffix

    $latestCustomerUpdate | Rename-Item -NewName { $_.Name -replace '\.md$', '_synced.md' }
}
