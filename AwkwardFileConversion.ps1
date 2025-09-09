# Import the CSV file
$registrations = Import-Csv -Path ".\awana registrations.csv"

# View the first object
$registrations | Select-Object -First 1 | Format-List

$flattened = @()

foreach ($row in $registrations) {
    # Split registrants on newlines, remove empty entries
    $registrantList = $row.Registrants -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
    foreach ($registrant in $registrantList) {
        $flattened += [PSCustomObject]@{
            'Registered By'      = $row.'Registered By'
            'Campus'             = $row.Campus
            'Confirmation Email' = $row.'Confirmation Email'
            'Registrant'         = $registrant.Trim()
            'When'               = $row.When
            'Total Cost'         = $row.'Total Cost'
            'Balance Due'        = $row.'Balance Due'
        }
    }
}


# Export the flattened list to a new CSV
$flattened | Export-Csv -Path ".\awana_registrants_flat.csv" -NoTypeInformation