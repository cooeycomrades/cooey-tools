# In this example, all licenses are assigned with groups, and credentials are passed through the Azure Function using Application Settings.
# In the example environment, the naming convention for these groups is "License-$licensename" and the E3 and E5 groups are not handled here.

# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Imports Module for Azure AD
Import-Module 'AzureADPreview' -UseWindowsPowerShell

# Connects to Azure AD using AAD and MS Graph Tokens
Connect-AzureAD `
    -AzureEnvironmentName AzureUSGovernment `
    -TenantId $env:MsGraphTenantId `
    -ApplicationId $env:MsGraphClientId `
    -CertificateThumbprint $env:MsGraphClientCertificate

# List user users with disabled access
$DisabledUsers = Get-AzureADUser -all $true | Where-Object AccountEnabled -eq $false

# List of all groups that assign licenses aside from the Base Office Suite. These are seperate because E3 is dynamic and E5 should be done manually.
$LicenseGroups = Get-AzureADGroup -SearchString License- | Where-Object DisplayName -NotLike "*Microsoft 365 E*"

ForEach ($User in $DisabledUsers)
    {
    #Creates List 
    $UserLicensedGroups = Get-AzureAdUserMembership -ObjectId $User.ObjectId | Where-Object ObjectId -in $LicenseGroups.ObjectId
    ForEach ($Group in $UserLicensedGroups)
        {
        Remove-AzureAdGroupMember -ObjectId $Group.ObjectId -MemberId $User.ObjectId -Verbose
        }
    }
