# Input and output file paths
$inputCsv = "C:\Users\gautamjha\Desktop\Removelan.csv"       # CSV should have a column named 'Username'
$outputCsv = "C:\Users\gautamjha\Desktop\RemoveReport.csv"

# Prepare results array
$results = @()

# Read CSV
$users = Import-Csv -Path $inputCsv

foreach ($user in $users) {
    $username = $user.Username
    $status = ""
    $errorMessage = ""

    try {
        # Get user object
        $adUser = Get-ADUser -Identity $username -Properties ProtectedFromAccidentalDeletion

        # Remove protection if enabled
        if ($adUser.ProtectedFromAccidentalDeletion) {
            Set-ADObject -Identity $adUser.DistinguishedName -ProtectedFromAccidentalDeletion $false
        }

        # Delete user
        Remove-ADUser -Identity $username -Confirm:$false
        $status = "Deleted"
    }
    catch {
        $status = "Failed"
        $errorMessage = $_.Exception.Message
    }

    # Add result to array
    $results += [PSCustomObject]@{
        Username = $username
        Status   = $status
        Error    = $errorMessage
    }
}

# Export results to CSV
$results | Export-Csv -Path $outputCsv -NoTypeInformation

Write-Host "User deletion process completed. Results saved to $outputCsv"