# Awana Messy CSV Conversion Script

This PowerShell script (`awanaMessyConversion.ps1`) converts a messy Awana registration CSV export into a clean, import-ready CSV. It handles parent/guardian parsing, grade normalization, address splitting, and more.

## Features

- **Parameterizable**: Specify input and output files via parameters.
- **Grade Normalization**: Converts grades to import guide values (`P0`, `P1`, ..., `K`, `1`–`12`, `Gr`).
- **Parent Parsing**: Extracts up to two parents/guardians, prioritizing those with phone numbers.
- **Extra Guardians**: Additional names are added to a `non_parent_pickup` field (max 50 chars).
- **Address Splitting**: Breaks address into street, city, state, and postal code.
- **Duplicate Filtering**: Optionally exclude records found in a previous file.

## Usage

Open PowerShell and run:

```powershell
.\awanaMessyConversion.ps1 -InputPath '.\AwanaMessy.csv' -OutputPath '.\AwanaParentsClean.csv'
```

### Optional: Exclude Old Records

If you want to exclude records already present in a previous file:

```powershell
.\awanaMessyConversion.ps1 -InputPath '.\AwanaMessy.csv' -OutputPath '.\AwanaParentsClean.csv' -OldInputPath '.\AwanaMessyOld.csv'
```

## Parameters

- `-InputPath` (required): Path to the messy input CSV file.
- `-OutputPath` (required): Path for the cleaned output CSV file.
- `-OldInputPath` (optional): Path to a previous CSV file for duplicate elimination.

## Notes

- The script expects the input CSV to have two extra header lines before the real header row.
- Parent/guardian names, emails, and phone numbers are matched by name after the dash in the phone field.
- If more than two parents/guardians are listed, only the first two (with phones prioritized) are used; others go into `non_parent_pickup`.
- Address parsing expects two or more spaces before the city, and a comma before the state.

## Example Input

```
Person Id,First Name,Last Name,Birth Date,Gender,Allergy,Grade,Parent's Names,Parent's Email Address,Parents' Phone Numbers,Address,Primary Family Id,Id
101,Alex,Smith,6/4/2015,Male,None,5th Grade,"Jordan Smith, Taylor Smith","jordan.smith@email.com, taylor.smith@email.com","(555) 123-4567 - Taylor, (555) 987-6543 - Jordan","1234 Main St  Sample City, ST 12345-6789",254,101
```

## Example Output

```
member_external_id,first_name,last_name,birth_date,gender,allergies,grade,parent_1_first_name,parent_1_last_name,parent_1_email,parent_1_cell_phone,parent_2_first_name,parent_2_last_name,parent_2_email,parent_2_cell_phone,non_parent_pickup,address_line_1,city,state,postal_code,household_external_id
101,Alex,Smith,6/4/2015,Male,None,5,Taylor,Smith,taylor.smith@email.com,(555) 123-4567,Jordan,Smith,jordan.smith@email.com,(555) 987-6543,,1234 Main St,Sample City,ST,12345-6789,254
```

## Troubleshooting

- **Script not found:** Use `.\awanaMessyConversion.ps1` (with `.\`) to run scripts in the current directory.
- **Execution policy error:** Run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` in your PowerShell session.
- **Parameter errors:** Ensure all required parameters are provided and are valid file paths.

---

**Author:**