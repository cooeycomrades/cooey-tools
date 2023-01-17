<# List-Exchange-Connected-Devices.ps1
.SYNOPSIS
    List Exchange Connected Devices. 

.DESCRIPTION 
    This was designed to show you all of the devices that are connected to your M365 Exchange environment which aren't listed in the MDM\MAM web portals.
    Includes Outlook mobile apps, 3rd party mail apps, basic auth, and the like. You want to be aware of these devices and how policy changes will affect them.
 
.NOTES 
    Author  :   Adam Kauffman   https://github.com/A9G-Data-Droid

.COMPONENT 
    ExchangeOnlineManagement is required and imported automatically.

.LINK 
    https://github.com/A9G-Data-Droid/cooey-tools/tree/main/scripts/powershell/Office-365/Exchange
#>

#Requires -Modules ExchangeOnlineManagement
#Requires -Version 5



<#
.SYNOPSIS
    Connect-Exchange-Stateful

.DESCRIPTION
    Connect & Login to Exchange Online (MFA). Won't reconnect if already connected
#>
function Connect-Exchange-Stateful {
    if (!(Get-PSSession | Where-Object {$_.Name -match 'ExchangeOnline' -and $_.Availability -eq 'Available'})) { 
        Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh -ShowBanner:$False
    }
}

Connect-Exchange-Stateful
Get-MobileDevice | Format-Table -Auto Identity, FriendlyName, DeviceOS, DeviceId

# How to remove them:
Write-Output "Cleanup old devices with the command: Remove-MobileDevice `"Identity`""
