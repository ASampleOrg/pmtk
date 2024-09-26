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
        $ConfigData,
        [Parameter()]
        [String]
        $WorkingDirectory
    )

    # for each row in the config file, create a new issue sync run
    foreach ($row in $ConfigData) {
        $customer = $row.customer
        $serviceIssue = $row.service_issue_id
        $serviceIssueRepo = $row.service_issue_repo
        $customerIssue = $row.customer_issue_id
        $customerIssueRepo = $row.customer_issue_repo
        $includeBurnDownChart = $row.include_burn_down
    
        # look for a directory with the same name as the customer
        # if it exists get the latest .md file that doesn't end with a _synced suffix in that directory 

        $customerDirectory = "$WorkingDirectory/$customer"
        Write-Output "Looking for update file for $customer in directory: $customerDirectory"

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

        # if the includeBurnDownChart flag is set, update the service issue with the burn down chart
        if ($includeBurnDownChart -eq $true) {
            Write-Output "Updating service issue $serviceIssue with burn down chart"
            Set-BurnDownChart -CustomerData $row 
    }

    # Update the .md file to have a _synced suffix

    Write-Output "Renaming update file: $($latestCustomerUpdate.FullName)"
    # Update the .md file to have a _synced suffix
    $newFileName = $latestCustomerUpdate.FullName -replace '\.md$', '_synced.md'
    Write-Output "Renaming update file: $($latestCustomerUpdate.FullName) to $newFileName"
    Rename-Item -Path $latestCustomerUpdate.FullName -NewName $newFileName
}
}


function Set-BurnDownChart {
    [CmdletBinding()]
    param (
        [Parameter()]
        [array]
        $CustomerData
    )

    $mermaidTemplate = @"
        ``````mermaid
            pie title {Customer} Hours Burndown from {HoursTotal} hours
                "Hours Done" : {HoursDone}
                "Hours Remaining" : {HoursRemaining}
        ``````
"@

    # using the gh cli get the markdown template for the mermaid chart, update the hours total with the burn down rate and post as a comment on the issue


    foreach ($item in $CustomerData) {
        $customer = $item.customer
        $serviceIssue = $item.service_issue_id
        $serviceIssueRepo = $item.service_issue_repo
        $customerIssue = $item.customer_issue_id
        $customerIssueRepo = $item.customer_issue_repo
        $burnDownTotal = $item.burn_down_total
        $burnDownRate = $item.burn_down_rate
        $burnDownMax = $item.burn_down_max

        # chart variables
        $date = Get-Date
        # calculate the current burn down by adding the rate to the total
        $currentBurnDown = $burnDownTotal + $burnDownRate


        $mermaidChart = $mermaidTemplate -replace '{Customer}', $customer `
                                         -replace '{Date}', $date `
                                         -replace '{HoursTotal}', $burnDownMax `
                                         -replace '{HoursDone}', $currentBurnDown `
                                         -replace '{HoursRemaining}', ($burnDownMax - $currentBurnDown)       

        Write-Output "Updating service issue $serviceIssue with burn down chart"                                    
        $result = & gh issue comment $serviceIssue -b $mermaidChart -R $serviceIssueRepo
        Write-Output "Service result: $result"

        Write-Output "Updating customer issue $customerIssue with burn down chart"
        $result = & gh issue comment $customerIssue -b $mermaidChart -R $customerIssueRepo
        Write-Output "Customer result: $result"
    }
}