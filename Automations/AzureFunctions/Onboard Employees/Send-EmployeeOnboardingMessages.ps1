<#
Author: @garrett-wood
Purpose: Automates the onboarding task of transmitting the welcome email and send the user an encrypted set of credentials
Requirements: This is written for addressing the MS Graph to send the email, and Freshservice API for the ITSM system. Adjust per your environment.
Usage: This function expects a secured webhook provideing a JSON payload in the following format

----
{
"name": "John Doe",
"username": "john.doe@contoso.com",
"password": "MyRandomSecurePassword12345!",
"tomail": "john.doe@personalmail.com",
"ticket": "123456"
}
----

You can modify the below attributes with adequate understanding of PowerShell if you can't send the payload in that format.
Once the webhook is received, the system sends the welcome email and then waits 30 seconds before sending the encryped creds.

It is expected that all credential components be passed through application settings.
#>

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

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

# Obtains MS Graph token
Write-Information "Obtaining Access Token for Microsoft Graph"
$Token = New-MsGraphAccessToken `
    -TenantId $env:MsGraphTenantId `
    -ClientId $env:MsGraphClientId `
    -ClientSecret $env:MsGraphClientSecret

# Sets up Credentials for Freshservice API
Write-Information "Building Freshservice API Credential"
[string]$userName = $env:FreshserviceApiKey
[string]$userPassword = 'x'
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
$FreshserviceDomain = ($env:FreshserviceDomain)

# Converts Webhook Body to a PSObject
$RequestObject = $Request.RawBody | ConvertFrom-Json
Write-Information "Converting Webhook from JSON to PS Object"
Write-Information $RequestObject

# Sets up Variables so they don't have be be escaped. Those based on Request Object come from a webhook, environment variables are stored in the function.
$ToEmail = $RequestObject.tomail
$ToName = $RequestObject.Name
$SenderGuid = $env:MsGraphEmailSenderId
$PayloadUsername = $RequestObject.username
$PayloadPassword = $RequestObject.password
$Ticket = $RequestObject.ticket

# Sets up Message Body to send message --- CONTENT MOSTLY REDACTED
$WelcomeMessage = "Hi $ToName, `
<br><br> `
Thank you for being a part of Contoso! We are happy to have you on the team. `
In order to get you up and running as quickly as possible, please reference the below items and reach out to the ServiceDesk with questions. Our contact information is at the bottom of this email. `
<br><br> `
<b>Logging In:</b><br> `
You will receive an encrypted email shortly which contains your Contoso username and password. You can follow the guide in the link below to open the email. Since Contoso uses Single Sign On for most of our systems, this is one of the few passwords you will need to remember here.<br> `
We look forward to working with you. Once again, welcome to Contoso. `
<br> `
<br> `
--- `
<br> `
Contoso ServiceDesk Team<br> `
Email: servicedesk@contoso.com<br> `
Web: https://contoso.freshservice.com<br>  `
Phone: (555) 555-5555 x555<br> `
"

$WelcomeMessageBody = @"
{
    "message": {
        "subject": "Welcome to Contoso",
        "body": {
            "contentType": "Html",
            "content": "$WelcomeMessage"
        },
        "toRecipients": [{
            "emailAddress": {
                "address": "$ToEmail"
            }
        }]
    }
}
}
"@

# Sends Initial Message to User
Write-Information "Sending welcome email to user."
Invoke-RestMethod `
    -Method Post `
    -ContentType 'application/json' `
    -Uri "https://$($Token.GraphHost)/v1.0/users/$SenderGuid/sendMail" `
    -Authentication Bearer `
    -Token $Token.BearerToken `
    -Body $WelcomeMessageBody

# Sets up Message Body to send message
$CredentialMessage = "Hi $ToName, `
<br><br> `
Your Contoso are below: `
<br><br> `
<b>Username:</b><br> `
$($RequestObject.username) `
<br><br> `
<b>Password:</b><br> `
$($RequestObject.password) `
<br><br> `
For assistance in resetting your password, please visit the following link: <br> `
LINK TO KB REMOVED `
<br> `
<br> `
Please test these credentials, and set your password as soon as possible. Note that some of your accounts may not be available until your start date. `
<br> `
<br> `
--- `
<br> `
Contoso ServiceDesk Team<br> `
Email: servicedesk@contoso.com<br> `
Web: https://contoso.freshservice.com<br>  `
Phone: (555) 555-5555 x555<br> `
"

$CredentialMessageBody = @"
{
    "message": {
        "subject": "Contoso Credentials *encrypt*",
        "body": {
            "contentType": "Html",
            "content": "$CredentialMessage"
        },
        "toRecipients": [{
            "emailAddress": {
                "address": "$ToEmail"
            }
        }]
    }
}
}
"@

# Waits 30 seconds to ensure the message that's unencrypted arrives first.
Write-Information "Waiting 30 seconds..."
Start-Sleep -Seconds 30 

# Sends Credentials to User
Write-Information "Sending credentials to user."
Invoke-RestMethod `
    -Method Post `
    -ContentType 'application/json' `
    -Uri "https://$($Token.GraphHost)/v1.0/users/$SenderGuid/sendMail" `
    -Authentication Bearer `
    -Token $Token.BearerToken `
    -Body $CredentialMessageBody

# Creates post content for updating the ticket in Freshservice
$TicketPostContent = @"
{
  "helpdesk_note": {
    "body":"The account for $ToName has been created. \n \n Username: \n $($RequestObject.username) \n \n Password: \n $($RequestObject.password)"
  }
}
"@

# Sends ticket update to freshservice
Write-Information "Updating ServiceDesk ticket."
Invoke-RestMethod `
    -Uri "$FreshserviceDomain/helpdesk/tickets/$ticket/conversations/note.json" `
    -Method Post `
    -Authentication Basic `
    -Credential $credObject `
    -ContentType 'application/json' `
    -Body $TicketPostContent

# Sets up payload for ticket close
$ClosePutContent = @"
{
   "helpdesk_ticket": { 
      "status":5
   }
}
"@

# Closes out onboarding ticket
Write-Information "Closing ServiceDesk ticket."
Invoke-RestMethod `
    -Uri "$FreshserviceDomain/helpdesk/tickets/$ticket.json" `
    -Method Put `
    -Authentication Basic `
    -Credential $credObject `
    -ContentType 'application/json' `
    -Body $ClosePutContent 
