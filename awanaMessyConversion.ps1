$inputPath = ".\AwanaMessy.csv"
$outputPath = ".\AwanaParentsClean.csv"

# Skip first 2 lines (extra headers)
$csv = Get-Content $inputPath | Select-Object -Skip 2 | ConvertFrom-Csv

$cleaned = foreach ($row in $csv) {
    $parents = ($row."Parent's Names" -split ',').ForEach({ $_.Trim() })
    $emails = ($row."Parent's Email Address" -split ',').ForEach({ $_.Trim() })
    $phones = ($row."Parents' Phone Numbers" -split ',').ForEach({ $_.Trim() })

    # Split parent names into first and last (splits on first space)
    $p1 = $parents[0] -split ' ', 2
    $p2 = $parents[1] -split ' ', 2

    $parent1Phone = ""
    $parent2Phone = ""

    foreach ($phone in $phones) {
        if ($phone -match '^\s*([\(\)\d\s\-]+)\s*-\s*(.+)$') {
            $number = $matches[1].Trim().TrimEnd('-',' ')
            $owner = $matches[2].Trim()
            if ($owner -like "*$($p1[0])*" -or $owner -like "*$($p1[1])*") {
                $parent1Phone = $number
            } elseif ($owner -like "*$($p2[0])*" -or $owner -like "*$($p2[1])*") {
                $parent2Phone = $number
            }
        }
    }

    # Split address into components
    $address = $row.'Address'
    $address_line_1 = ""
    $city = ""
    $state = ""
    $postal_code = ""

    if ($address -match '^(.*)\s+([A-Za-z\s]+),\s*([A-Z]{2})\s*(\d{5}(?:-\d{4})?)$') {
        $address_line_1 = $matches[1].Trim()
        $city = $matches[2].Trim()
        $state = $matches[3].Trim()
        $postal_code = $matches[4].Trim()
    } else {
        $address_line_1 = $address
    }

    [PSCustomObject]@{
        'member_external_id'    = $row.'Person Id'
        'first_name'            = $row.'First Name'
        'last_name'             = $row.'Last Name'
        'birth_date'            = $row.'Birth Date'
        'gender'                = $row.'Gender'
        'allergies'             = $row.'Allergy'
        'grade'                 = $row.'Grade'
        'parent_1_first_name'   = $p1[0]
        'parent_1_last_name'    = $p1[1]
        'parent_1_email'        = $emails[0]
        'parent_1_cell_phone'   = $parent1Phone
        'parent_2_first_name'   = $p2[0]
        'parent_2_last_name'    = $p2[1]
        'parent_2_email'        = $emails[1]
        'parent_2_cell_phone'   = $parent2Phone
        'address_line_1'        = $address_line_1
        'city'                  = $city
        'state'                 = $state
        'postal_code'           = $postal_code
    }
}

$cleaned | Export-Csv -Path $outputPath -NoTypeInformation