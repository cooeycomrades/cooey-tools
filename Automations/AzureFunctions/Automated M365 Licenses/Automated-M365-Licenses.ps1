<#
Author: @garrett-wood
Purpose: To be run in a PowerShell Azure Function to automatically assign licenses when requests through Freshservice Service Catalog. Total time to license
assignment when using this method is under 5 seconds from supervisor approval to assignment. Will also alert a human when licenses are getting low.
#>

# Note that you MUST setup custom statuses in Freshservice and pipe your own values in. This is specific to our workflow. Sub in yours.
# In the example environment, the naming convention for these groups is "License-$licensename" and the E3 and E5 groups are not handled here.

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

<# This functions expects the following format as an input for verification requests

{
"licensedSku": "{{R3.sku_guid}}",
"ticketNumber": "{{ticket.id_numeric}}",
"licenseName": "{{R3.license_type_value}}",
"operation": "verify"
}

and the following format for assignment requests

{
"licensedSku": "{{R3.sku_guid}}",
"ticketNumber": "{{ticket.id_numeric}}",
"licenseName": "{{R3.license_type_value}}",
"operation": "assign",
"licensedUser": "{{ticket.actual_requester.email}}",
"licensedGroup": "{{R3.group_guid}}"
}

#> 

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

#########################################################################################################################################
#                                                                                                                                       #
#                                                 SECTION 1 - REQUIRED FUNCTIONS                                                        #
#                                                                                                                                       #
#########################################################################################################################################

# Defines custom function to get MS Graph access token.
function New-MsGraphAccessToken 
{
Param 
    (
    # Should probably validate these in some way.
    $TenantId,
    $ClientId,
    $ClientSecret
)
    # Pulls proper Graph and Token endpoints from Domain using Well Known OpenId Configuration Endpoint
    $TenantWellKnown = Invoke-RestMethod -uri "https://login.microsoftonline.com/$TenantId/v2.0/.well-known/openid-configuration"
    $GraphEndpoint = $TenantWellKnown.msgraph_host
    $TokenEndpoint = $TenantWellKnown.token_endpoint

    # Sends request to acquire bearer token
    $ApiConnection = Invoke-RestMethod `
    -Method Post `
    -Uri $TokenEndpoint `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body @{
        client_id = "$ClientId"
        scope =  "https://$GraphEndpoint/.default"
        client_secret = "$ClientSecret"
        grant_type = "client_credentials"
    }
    # Returns PSObject which contains the token as a secure string, graph and point and Tenant Id. These are returned in case
    # further references are needed in dependent functions.
    $BearerToken = ($ApiConnection.access_token | ConvertTo-SecureString -AsPlainText -Force)
    $Output = New-Object -TypeName PSObject
    $Output | Add-Member -MemberType NoteProperty -Name BearerToken -Value $BearerToken
    $Output | Add-Member -MemberType NoteProperty -Name GraphHost -Value $GraphEndpoint
    $Output | Add-Member -MemberType NoteProperty -Name TenantScope -Value $TenantId
    Return $Output
}

#########################################################################################################################################
#                                                                                                                                       #
#                                                    SECTION 2 - VARIABLE ASSIGNMENT                                                    #
#                                                                                                                                       #
#########################################################################################################################################

# Converts Freshservice Payload to PowerShell formatting
Write-Information "The following was receieved as a webhook"
Write-Information $Request.RawBody
$LicenseOperation = $Request.RawBody | Convertfrom-Json

# Obtains MS Graph token. This is used to send the email.
Write-Information "Obtaining Access Token for Microsoft Graph"
$Token = New-MsGraphAccessToken `
    -TenantId $env:MsGraphTenantId `
    -ClientId $env:MsGraphClientId `
    -ClientSecret $env:MsGraphClientSecret
    
# Retreives a list of all licenses for the tenant
Write-Information "Checking Current License Status"
$GraphLicenses = Invoke-RestMethod `
     -Method Get `
     -ContentType 'application/json' `
     -Uri "https://$($Token.GraphHost)/v1.0/subscribedSkus" `
     -Authentication Bearer `
     -Token $Token.BearerToken | Select -expand value

# Sets up Message Body to send message
$WarningMessage = "Hi Service Desk Team, `
<br><br> `
Human intervention may soon be required on the Service Request for #SR-$($LicenseOperation.ticketNumber). `
<br><br> `
The following License is currently at critical assignment status (greater than 95% allocated and/or 3 or fewer left). `
<br><br> `
<b>Name:</b><br> `
$($LicenseOperation.licenseName) `
<br><b>Sku Id:</b><br> `
$($LicenseOperation.licensedSku) `
<br><br> `
Please re-evaluate current license counts, terminate inactive licenses or purchase more ASAP. `
<br> `
<br> `
--- `
<br> `
Automation Orchestrator<br> `
"
# CHANGE THIS TO ADDRESS VALUE
$WarningMessageBody = @"
{
    "message": {
        "subject": "Critical License Threshold - $($LicenseOperation.licenseName)",
        "body": {
            "contentType": "Html",
            "content": "$WarningMessage"
        },
        "toRecipients": [{
            "emailAddress": {
                "address": "servicedesk@contoso.com"
            }
        }]
    }
}
}
"@

# Sets up Credentials for Freshservice API
Write-Information "Building Freshservice Credential Object"
$FreshserviceApiKey = $env:FreshserviceApiKey
$FreshserviceApiPss = 'x' | ConvertTo-SecureString -AsPlainText -Force
$FsCredential = New-Object System.Management.Automation.PSCredential ($FreshserviceApiKey, $FreshserviceApiPss)
$FreshserviceDomain = ($env:FreshserviceDomain)

# Updates Freshservice Ticket to Alert User
$TicketPostContent = @"
{
  "helpdesk_note": {
    "body":"We are currently running low on these licenses and may be out by the time your supervisor approves your request. If this happens, we will keep you updated.",
    "private":false
  }
}
"@

# Updates Freshservice Ticket to Alert User
$CapacityPostContent = @"
{
  "helpdesk_note": {
    "body":"We no longer have any licenses available to meet this request. The Service Desk team has already been alerted and will keep you updated.",
    "private":false
  }
}
"@

# Updates Freshservice Ticket to Alert User
$SuccessPostContent = @"
{
  "helpdesk_note": {
    "body":"This license has been assigned to you. Note that this change can take up to an hour to process. Please let us know if anything further is needed.",
    "private":false
  }
}
"@

#########################################################################################################################################
#                                                                                                                                       #
#                                    SECTION 3 - VERIFY LICENSE COUNT AND NOTIFY IF REACHED THRESHOLD                                   #
#                                                                                                                                       #
#########################################################################################################################################

# Gets values for current assignments and maximum assignments
$Consumed = $GraphLicenses | Where-Object SkuId -eq $LicenseOperation.licensedSku | Select -expand consumedUnits
$Maximum  = $GraphLicenses | Where-Object SkuId -eq $LicenseOperation.licensedSku | Select -expand prepaidunits | Select -Expand Enabled
Write-Information "Licenses Consumed: $Consumed"
Write-Information "Licenses Maximum: $Maximum"
$ConsumptionRatio = $Consumed / $Maximum
$AvailableLicenses = $Maximum - $Consumed
$CriticalThreshold = ($ConsumptionRatio -gt .95) -or ($AvailableLicenses -lt 4)
$FullyCommitted = ($AvailableLicenses -lt 1)

# Sends a warning if license usage has reached critical threshold
If ($CriticalThreshold)
{
# Sends a Warning to the ServiceDesk. TODO - Store the GUID for the orchestrator account as a variable.
Write-Information "Opening a ticket with the servicedesk due to critical license count"
Invoke-RestMethod `
    -Method Post `
    -ContentType 'application/json' `
    -Uri "https://$($Token.GraphHost)/v1.0/users/00000000-0000-0000-0000-000000000000/sendMail" `
    -Authentication Bearer `
    -Token $Token.BearerToken `
    -Body $WarningMessageBody

# Sends ticket update to freshservice
Write-Information "Updating ServiceDesk ticket with critical license issue."
Invoke-RestMethod `
    -Uri "$FreshserviceDomain/helpdesk/tickets/$ticket/conversations/note.json" `
    -Method Post `
    -Authentication Basic `
    -Credential $FsCredential `
    -ContentType 'application/json' `
    -Body $TicketPostContent
}

#########################################################################################################################################
#                                                                                                                                       #
#                                                SECTION 4 - ASSIGN AND/OR UPDATE TICKET                                                #
#                                                                                                                                       #
#########################################################################################################################################

# If capacity has been reached, update the ticket.
If ($FullyCommitted)
    {
    # Sends ticket update to freshservice
    Write-Information "No licenses left to assign."
    Invoke-RestMethod `
        -Uri "$FreshserviceDomain/helpdesk/tickets/$ticket/conversations/note.json" `
        -Method Post `
        -Authentication Basic `
        -Credential $FsCredential `
        -ContentType 'application/json' `
        -Body $CapacityPostContent
    }
# If Capacity has not yet been reached, and the operation is to assign, then assign the license. TODO: Add check to see if user is currently member
ElseIf ($LicenseOperation.operation -eq 'assign')
    {
    # Obtains User Guid
    $User = Invoke-RestMethod `
        -Method Get `
        -ContentType 'application/json' `
        -Uri "https://$($Token.GraphHost)/v1.0/users/$($LicenseOperation.licensedUser)" `
        -Authentication Bearer `
        -Token $Token.BearerToken
    Write-Information "Found User based on UPN"
    Write-Information $User

    # Adds User To Group
    Invoke-RestMethod `
        -Method Post `
        -ContentType 'application/json' `
        -Uri "https://$($Token.GraphHost)/v1.0/groups/$($LicenseOperation.licensedGroup)/members/`$ref" `
        -Authentication Bearer `
        -Token $Token.BearerToken `
        -Body (@{ "@odata.id" = "https://$($Token.GraphHost)/v1.0/directoryObjects/$($User.id)" } | ConvertTo-Json)

    # Updates Freshservice Ticket
    Write-Information "Updating ServiceDesk ticket with success."
    Invoke-RestMethod `
        -Uri "$FreshserviceDomain/helpdesk/tickets/$($LicenseOperation.ticketNumber)/conversations/note.json" `
        -Method Post `
        -Authentication Basic `
        -Credential $FsCredential `
        -ContentType 'application/json' `
        -Body $SuccessPostContent

    # Sets ticket to waiting on customer
    Write-Information "Setting ticket to waiting on customer"
    Invoke-RestMethod `
        -Uri "$FreshserviceDomain/helpdesk/tickets/$ticket.json" `
        -Method Put `
        -Authentication Basic `
        -Credential $FsCredential `
        -ContentType 'application/json' `
        -Body (@{'helpdesk_ticket' = @{'status' = 7}} | ConvertTo-Json)
    
    }
