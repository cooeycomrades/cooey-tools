
<#
Author: @garrett-wood
Purpose: To be run on a cron timer to disable access to powershell for users that don't need it as that's occaisitonally used as an attack vector and there's no way
to do so with Conditional Access policies
#>

# Ensure you swap the Environment (if needed) and VERIFY your admin account(s) are excempted. 
# Note that you will NEED to grant your application manageAsApp permissions to do this. This involves editing the manifest.
# See: https://docs.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps

# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Connects to Exchange Online - Swap a different value if you're not in GCCH
Write-Host "Connecting to EXO..."
Connect-ExchangeOnline `
    -ExchangeEnvironmentName O365USGovGCCHigh `
    -AppId $env:MsGraphClientId `
    -CertificateThumbprint $env:MsGraphClientCertificate `
    -Organization $env:ExchangeOrganizationName

# Gets list of non admin and non service account users according to naming convention. Change this to fit yours, or don't. I'm a comment, not a cop.
$UnprivilegedUsers = Get-User -ResultSize unlimited -Filter `
"(UserPrincipalName -notlike 'a-*') `
-and (UserPrincipalName -notlike 'ga-*') `
-and (UserPrincipalName -notlike 'svc-*') `
-and (RemotePowerShellEnabled -eq 'true')"
Write-Host "$($UnprivilegedUsers.Count) users in need of disabling were found!"

# Sets users as unable to user remote powershell
if ($UnprivilegedUsers)
    {
    $UnprivilegedUsers | foreach {
        Set-User -Identity $_.DistinguishedName -RemotePowerShellEnabled $false
        Write-Host "Disabled Remote PowerShell for $($_.Name)"
        }
    }
# If no users were found, report.
Else
    {Write-Host "All in-scope accounts already have Remote PowerShell disabled."}
