function Get-ConfigAsPSObject {
    param(
        [string] $filePath
    )

    if (-Not (Test-Path -Path $filePath)) {
        throw "Configuration file not found: $filePath"
    }

    $configContent = Get-Content -Path $filePath
    $configObject = [PSCustomObject]@{}

    foreach ($line in $configContent) {
        if ($line -match '^\s*#') {
            continue  # Skip comment lines
        }

        if ($line -match '^\s*$') {
            continue  # Skip empty lines
        }

        $key, $value = $line -split '=', 2
        $configObject | Add-Member -MemberType NoteProperty -Name $key.Trim() -Value $value.Trim()
    }

    return $configObject
}