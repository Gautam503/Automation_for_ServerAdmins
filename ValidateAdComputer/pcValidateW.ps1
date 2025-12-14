#### computer ka list jo ad mai exits krta h nhi
$computers = Import-Csv "C:\Users\gautamjha\Desktop\computer06.csv"

$Report = foreach ($row in $computers) {
    $pcName = $row.ComputerName.Trim()

    # AD me search karo
    $pc = Get-ADComputer -Filter { Name -eq $pcName } -Properties Enabled, LastLogonDate -ErrorAction SilentlyContinue

    if ($null -ne $pc) {
        # Agar AD me mila
        [PSCustomObject]@{
            ComputerName = $pcName
            InAD         = "Yes"
            Status       = if ($pc.Enabled) { "Enabled" } else { "Disabled" }
            LastLogon    = $pc.LastLogonDate
        }
    }
    else {
        # Agar AD me hi nahi mila
        [PSCustomObject]@{
            ComputerName = $pcName
            InAD         = "No"
            Status       = "Not Found in AD"
            LastLogon    = "N/A"
        }
    }
}

Export CSV
$Report | Export-Csv "C:\Users\gautamjha\Desktop\CReport0PC.csv" -NoTypeInformation -Encoding UTF8

