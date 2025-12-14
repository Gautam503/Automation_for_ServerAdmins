<#
Bulk password reset script
- Sets password: Proliant!@2026#$
- User CANNOT change password
- User is NOT forced to change at next logon
- Logs successes and failures
#>

# --- Configuration ---
$CsvPath     = "C:\Users\gautamjha\Desktop\passRe.csv"  # CSV must have SamAccountName or UserPrincipalName column
$LogPath     = "C:\Users\gautamjha\Desktop\BulkPasswordReset_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$NewPassword = "Proliant!@2026#$"  # Ensure this meets your domain password policy

# --- Start ---
Import-Module ActiveDirectory -ErrorAction Stop

# Validate CSV
if (-not (Test-Path -LiteralPath $CsvPath)) {
    Write-Error "CSV file not found: $CsvPath"
    exit 1
}

# Read users (normalize headers to avoid trailing-space issues)
$raw = Import-Csv -LiteralPath $CsvPath
if (-not $raw -or $raw.Count -eq 0) {
    Write-Error "CSV appears empty. Provide at least one SamAccountName or UserPrincipalName."
    exit 1
}

# Normalize property names (trim header keys)
# This ensures 'SamAccountName ' becomes 'SamAccountName'
$users = foreach ($row in $raw) {
    $ht = @{}
    foreach ($prop in $row.PSObject.Properties) {
        $trimmedName = ($prop.Name).Trim()
        $ht[$trimmedName] = $prop.Value
    }
    [PSCustomObject]$ht
}

# Logging helper
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] $Message"
    Write-Host $line
    Add-Content -LiteralPath $LogPath -Value $line
}

Write-Log "=== Bulk Password Reset Started ==="
Write-Log "CSV: $CsvPath"
Write-Log "Log: $LogPath"

foreach ($row in $users) {
    try {
        # Determine lookup key
        $identity =
            if ($row.SamAccountName)     { $row.SamAccountName }
            elseif ($row.UserPrincipalName) { $row.UserPrincipalName }
            else { $null }

        if (-not $identity) {
            Write-Log "SKIP: Row missing SamAccountName/UserPrincipalName. Raw row: $($row | ConvertTo-Json -Compress)"
            continue
        }

        $u = Get-ADUser -Identity $identity -Properties CannotChangePassword, pwdLastSet -ErrorAction Stop

        Write-Log "Processing user: $($u.SamAccountName) (DN: $($u.DistinguishedName))"

        # Reset password
        Set-ADAccountPassword -Identity $u -Reset -NewPassword (ConvertTo-SecureString $NewPassword -AsPlainText -Force)

        # Ensure NOT forced to change at next logon
        # Clearing the 'must change at next logon' flag is done by setting pwdLastSet = -1
        Set-ADUser -Identity $u -Replace @{pwdLastSet = -1}

        # Set: user cannot change password
        # This toggles the ACL so the user is denied the 'Change Password' right
        Set-ADUser -Identity $u -CannotChangePassword $true

        Write-Log "SUCCESS: $($u.SamAccountName) password reset; cannot change password; no force at next logon."
    }
    catch {
        Write-Log "ERROR: $identity — $($_.Exception.Message)"
        continue
    }
}

Write-Log "=== Bulk Password Reset Complete ==="
Write-Log "Review log for details: $LogPath"
