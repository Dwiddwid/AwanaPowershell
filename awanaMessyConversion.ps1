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

    # Extract only the phone number using regex and trim any trailing dash or space
    $phone1 = if ($phones[0]) { ($phones[0] -match '^\s*([\(\)\d\s\-]+)') | Out-Null; $matches[1].Trim().TrimEnd('-',' ') } else { "" }
    $phone2 = if ($phones[1]) { ($phones[1] -match '^\s*([\(\)\d\s\-]+)') | Out-Null; $matches[1].Trim().TrimEnd('-',' ') } else { "" }

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
        'parent_1_cell_phone'   = $phone1
        'parent_2_first_name'   = $p2[0]
        'parent_2_last_name'    = $p2[1]
        'parent_2_email'        = $emails[1]
        'parent_2_cell_phone'   = $phone2
        'address_line_1'        = $row.'Address'
    }
}

$cleaned | Export-Csv -Path $outputPath -NoTypeInformation