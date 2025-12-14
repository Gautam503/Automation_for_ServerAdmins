# Store the data from NewUsersFinal.csv in the $ADUsers variable
$ADUsers = Import-Csv "C:\Users\gautamjha\Desktop\NewUsersFinal1Dec.csv"

# Define UPN
$UPN = "yourcompany.in"

# Loop through each row containing user details in the CSV file
foreach ($User in $ADUsers) {
    try {
        # Define the parameters using a hashtable
        $UserParams = @{
            SamAccountName        = $User.UserName
            UserPrincipalName     = "$($User.UserName)@$UPN"
            Name                  = "$($User.FirstName) $($User.LastName)"
            GivenName             = $User.FirstName
            Surname               = $User.LastName
            Enabled               = $True
            DisplayName           = "$($User.FirstName) $($User.LastName)"
            Path                  = $User.OU
			Description           = $User.Grade
            EmailAddress          = $User.FinalEmail
            EmployeeID            = $User.EmployeeID
			MobilePhone			  = $User.Mobile
            AccountPassword       = (ConvertTo-secureString $User.Password -AsPlainText -Force)
            ChangePasswordAtLogon = $True
        }

        # Check to see if the user already exists in AD
        if (Get-ADUser -Filter "SamAccountName -eq '$($User.UserName)'") {

            # Give a warning if user exists
            Write-Host "A user with UserName $($User.UserName) already exists in Active Directory." -ForegroundColor Yellow
        }
        else {
            # User does not exist then proceed to create the new user account
            # Account will be created in the OU provided by the $User.ou variable read from the CSV file
            New-ADUser @UserParams

            # If user is created, show message.
            Write-Host "The user $($User.UserName) is created." -ForegroundColor Green
        }
    }
    catch {
        # Handle any errors that occur during account creation
        Write-Host "Failed to create user $($User.UserName) - $_" -ForegroundColor Red
    }
}
