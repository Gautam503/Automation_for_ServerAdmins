# Paths
$inputCsv = "C:\Users\gautamjha\Desktop\empIDtoemail.csv"
$outputCsv = "C:\Users\gautamjha\Desktop\email_results.csv"
$missingLog = "C:\Users\gautamjha\Desktop\missing_employees.txt"

# Import employee IDs
$employees = Import-Csv -Path $inputCsv

# Prepare result array
$result = @()

foreach ($entry in $employees) {
    $empID = $entry.EmployeeID
    $user = Get-ADUser -Filter "EmployeeID -eq '$empID'" -Properties EmailAddress

    if ($user) {
        $result += [PSCustomObject]@{
            EmployeeID   = $empID
            Name         = $user.Name
            EmailAddress = $user.EmailAddress
        }
    } else {
        Add-Content -Path $missingLog -Value "EmployeeID $empID not found in AD on $(Get-Date)"
    }
}

# Export results to CSV
$result | Export-Csv -Path $outputCsv -NoTypeInformation

Write-Host "? Export complete. Results saved to $outputCsv"
Write-Host "? Missing entries logged to $missingLog"
