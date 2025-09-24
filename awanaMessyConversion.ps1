param(
    [Parameter(Mandatory)]
    [string]$InputPath,

    [Parameter(Mandatory)]
    [string]$OutputPath,

    # old file for potential record elimination
    [string]$OldInputPath = $null
)
# $inputPath = ".\AwanaMessy.csv"
# $oldInputPath = ".\AwanaMessyOld.csv"
# $outputPath = ".\AwanaParentsClean.csv"

# Skip first 2 lines (extra headers)
$csv = Get-Content $InputPath | Select-Object -Skip 2 | ConvertFrom-Csv
if ($OldInputPath) {
    $oldCsv = Get-Content $OldInputPath | Select-Object -Skip 2 | ConvertFrom-Csv
    $oldIds = $oldCsv.'Person Id' | Sort-Object -Unique
    $csv = $csv | Where-Object { $oldIds -notcontains $_.'Person Id' }
}

# Grade mapping table
$gradeMap = @{
    "Kindergarten" = "K"
    "TK"           = "TK"
    "Graduate"     = "Gr"
    "P0"           = "P0"
    "P1"           = "P1"
    "P2"           = "P2"
    "P3"           = "P3"
    "P4"           = "P4"
}

function Convert-Grade($grade) {
    if ($null -eq $grade -or $grade -eq "") { return "" }
    $g = $grade.Trim().ToLower()
    if ($gradeMap.ContainsKey($grade)) { return $gradeMap[$grade] }
    if ($g -match '^(\d+)(st|nd|rd|th)? grade$') { return $matches[1] }
    if ($g -match '^(\d+)$') { return $matches[1] }
    if ($g -eq "k" -or $g -eq "kindergarten") { return "K" }
    if ($g -eq "graduate" -or $g -eq "gr") { return "Gr" }
    if ($g -eq "tk") { return "TK" }
    if ($g -match '^p[0-4]$') { return $g.ToUpper() }
    return $grade
}

$cleaned = foreach ($row in $csv) {
    $parents = ($row."Parent's Names" -split ',').ForEach({ $_.Trim() })
    $emails = ($row."Parent's Email Address" -split ',').ForEach({ $_.Trim() })
    $phones = ($row."Parents' Phone Numbers" -split ',').ForEach({ $_.Trim() })

    # Build a parent info array
    $parentInfos = @()
    for ($i = 0; $i -lt $parents.Count; $i++) {
        $nameParts = $parents[$i] -split ' ', 2
        $parentInfos += [PSCustomObject]@{
            Index     = $i
            Name      = $parents[$i]
            FirstName = $nameParts[0]
            LastName  = if ($nameParts.Count -gt 1) { $nameParts[1] } else { "" }
            Email     = if ($emails.Count -gt $i) { $emails[$i] } else { "" }
            Phone     = ""
            HasPhone  = $false
        }
    }

    # Convert grade
    $importGrade = Convert-Grade $row.'Grade'

    # Assign phones to parents by matching owner name
    foreach ($phone in $phones) {
        if ($phone -match '^\s*([\(\)\d\s\-]+)\s*-\s*(.+)$') {
            $number = $matches[1].Trim().TrimEnd('-',' ')
            $owner = $matches[2].Trim()
            foreach ($p in $parentInfos) {
                if ($owner -like "*$($p.FirstName)*" -or $owner -like "*$($p.LastName)*") {
                    $p.Phone = $number
                    $p.HasPhone = $true
                    break
                }
            }
        }
    }

    # Sort parents: those with phones first
    $sortedParents = @($parentInfos | Sort-Object -Property { -not $_.HasPhone }, Index)

    # Assign parent_1 and parent_2
    $parent1 = if ($sortedParents.Count -gt 0) { $sortedParents[0] } else { $null }
    $parent2 = if ($sortedParents.Count -gt 1) { $sortedParents[1] } else { $null }

    # Any extras go to non_parent_pickup (comma separated, max 50 chars)
    $extraParents = @()
    if ($sortedParents.Count -gt 2) {
        $extraParents = $sortedParents[2..($sortedParents.Count-1)] | ForEach-Object { $_.Name }
    }
    $non_parent_pickup = ($extraParents -join ', ')
    if ($non_parent_pickup.Length -gt 50) {
        $non_parent_pickup = $non_parent_pickup.Substring(0,50)
    }

    # Split address into components (handles multi-word cities)
    $address = $row.'Address'
    $address_line_1 = ""
    $city = ""
    $state = ""
    $postal_code = ""

    if ($address -match '^(.*?)(?:\s{2,})([A-Za-z .]+),\s*([A-Z]{2})\s*(\d{5}(?:-\d{4})?)$') {
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
        'grade'                 = $importGrade
        'parent_1_first_name'   = if ($parent1) { $parent1.FirstName } else { "" }
        'parent_1_last_name'    = if ($parent1) { $parent1.LastName } else { "" }
        'parent_1_email'        = if ($parent1) { $parent1.Email } else { "" }
        'parent_1_cell_phone'   = if ($parent1) { $parent1.Phone } else { "" }
        'parent_2_first_name'   = if ($parent2) { $parent2.FirstName } else { "" }
        'parent_2_last_name'    = if ($parent2) { $parent2.LastName } else { "" }
        'parent_2_email'        = if ($parent2) { $parent2.Email } else { "" }
        'parent_2_cell_phone'   = if ($parent2) { $parent2.Phone } else { "" }
        'non_parent_pickup'     = $non_parent_pickup
        'address_line_1'        = $address_line_1
        'city'                  = $city
        'state'                 = $state
        'postal_code'           = $postal_code
        'household_external_id' = $row.'Primary Family Id'
    }
}
$cleaned | Export-Csv -Path $OutputPath -NoTypeInformation