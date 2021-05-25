  
<#
Author: @garrett-wood
Purpose: This will be called by Freshservice whenever a Contractor Service Catalog Request is initiated. ALL of this is environmentally specific and is intended
only to give you an idea of what and how something can be done. There is no real way to make a for dummies guide on this. You just need to read and understand it.
#>

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

#########################################################################################################################################
#                                                                                                                                       #
#                                                 SECTION 1 - REQUIRED FUNCTIONS                                                        #
#                                                                                                                                       #
#########################################################################################################################################
<# 
Generates Passwords Securely using RNGCryptoServiceProvider in a human readable form. Not really necessary to use the XKCD style here 
since these will be federated accounts, but I already wrote the function so it does save time. Modified to static path for the 
dictionaries. Any reuse of this function would require the manual addition of those dictionaries until I get around to placing this in 
the PS Gallery. Note that this function is actually fair computationally expensive. Using a less secure Get-Random on a dictionary of 
symbols may be a better fit depending on organizational needs and use context.
#>

function New-SecurePassword 
{
    [cmdletBinding()]
    [OutputType([string])]
    
    Param
    ( 
        [ValidateRange(1,24)]
        [int]
        $MinWordLength = 6,
        
        [ValidateRange(1,24)]        
        [int]
        $MaxWordLength = 12,
        
        [ValidateRange(1,24)]        
        [int]
        $WordCount = 2,
        
        [ValidateRange(1,24)]        
        [int]
        $Count = 1,
        
        [int]$MaxLength = 65535, 
        
        [switch]$NoSymbols = $False, 
        
        [switch]$NoNumbers = $False 

    )
        
    # Modified for this script - declares known location for dictionary files
    $LocalPath = 'D:\home\site\wwwroot\modules\XKCDPasswordGenDictionary\'

    #GENERATE RANDOM PASSWORD(S)
    $FinalPasswords = @()
    For( $Passwords=1; $Passwords -le $Count; $Passwords++ )
    {
    
        #GENERATE RANDOM LENGTHS FOR EACH WORD
        $WordLengths =  @()
        For( $Words=1; $Words -le $WordCount; $Words++ ) 
            {
            [System.Security.Cryptography.RNGCryptoServiceProvider]  $Random = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
            $RandomNumber = new-object byte[] 1
            $WordLength = ($Random.GetBytes($RandomNumber))
            [int] $WordLength = $MinWordLength + $RandomNumber[0] % 
            ($MaxWordLength - $MinWordLength + 1) 
            $WordLengths += $WordLength 
            }
        
        #PICK WORD FROM DICTIONARY MATCHING RANDOM LENGTHS
        $RandomWords = @()
        ForEach ($WordLength in $WordLengths)
            {
            $DictionaryPath = ($LocalPath + 'Words_' + $WordLength + '.txt')
            $Dictionary = Get-Content -Path $DictionaryPath
            $MaxWordIndex = Get-Content -Path $DictionaryPath | Measure-Object -Line | Select -Expand Lines
            $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
            $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
            #I don't know why but when the below line is commented out, the function breaks and returns the same words each time.
            $RandomSeed = $Random.GetBytes($RandomBytes)
            $RNG = [BitConverter]::ToUInt32($RandomBytes, 0)
            $WordIndex = ($Random.GetBytes($RandomBytes))
            [int] $WordIndex = 0 + $RNG[0] % 
            ($MaxWordIndex - 0 + 1)
            $RandomWord = $Dictionary | Select -Index $WordIndex
            $RandomWords += $RandomWord
            }

        #RANDOMIZE CASE
        $RandomCaseWords = ForEach ($RandomWord in $RandomWords) 
            {
            $ChangeCase = Get-Random -InputObject $True,$False
            If ($ChangeCase -eq $True) 
                {
                $RandomWord.ToUpper()
                }
            Else 
                {
                $RandomWord
                }
            }

        #ADD SYMBOLS
        If ($NoSymbols -eq $True) 
            {
            $RandomSymbolWords = $RandomCaseWords
            }
        Else 
            {
            $RandomSymbolWords = ForEach ($RandomCaseWord in $RandomCaseWords) 
                {
                $Symbols = @('!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '=', '+')
                $Prepend = Get-Random -InputObject $Symbols
                $Append = Get-Random -InputObject $Symbols
                [System.String]::Concat($Prepend, $RandomCaseWord, $Append)
                }
            }
    
        #ADD NUMBERS
        If ($NoNumbers -eq $True) 
            {
            $NumberedPassword = $RandomSymbolWords
            }
        Else 
            {
            $NumberedPassword = ForEach ($RandomSymbolWord in $RandomSymbolWords) 
                {
                $Numbers = @("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
                $Prepend = Get-Random -InputObject $Numbers
                $Append = Get-Random -InputObject $Numbers
                [System.String]::Concat($Prepend, $RandomSymbolWord, $Append)
                }
            }

        #JOIN ALL ITEMS IN ARRAY
        $FinalPasswordString = $NumberedPassword -Join ''

        #PERFORM FINAL LENGTH CHECK
        If ($FinalPasswordString.Length -gt $MaxLength) 
            {
            $FinalPassword = $FinalPasswordString.substring(0, $MaxLength)
            }
        Else 
            {
            $FinalPassword = $FinalPasswordString
            }

        #JOIN GENERATED PASSWORDS TO ARRAY
        $FinalPasswords += $FinalPassword

    }

    #PROVIDE RANDOM PASSWORD  
    Return $FinalPasswords
}

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

<# This function is supposed to receive the following as a webhook
{
"displayName": "{{ticket.ri_44_cf_full_name}}",
"givenName": "{{ticket.ri_44_cf_first_name}}",
"surname": "{{ticket.ri_44_cf_lastname}}",
"sAMAccountName": "tbd",
"userPrincipalName": "tbd",
"accountExpirationDate": "{{ticket.ri_44_cf_contract_end_date}}",
"accountPassword": "tbd",
"employeeId": "tbd",
"jobTitle": "{{ticket.ri_44_cf_job_title}}",
"manager": "{{ticket.actual_requester.email}}",
"department": "{{ticket.ri_44_cf_department}}"
"company": "{{ticket.ri_44_cf_company}}",
"ticket": "{{ticket.id}}",
"ticketnumber": "{{ticket.id_numeric}}"
}
#>


# Converts Escapes for easier transfer
Write-Host $Request.RawBody
$ContractorRequest = $Request.RawBody | ConvertFrom-Json
$AdOuPath = $env:AdOrganizationalUnit
$fsticket = $ContractorRequest.ticketnumber

# Sets up credential to talk to Active Directory using Application Settings from the function
Write-Information "Building Active Directory Credential Object"
$AdUserManagerUpn = $env:AdUserPrincipalNamePrefix + '@' + $env:AdDomainName
$AdUserManagerPss = $env:AdPassword| ConvertTo-SecureString -AsPlainText -Force
$AdCredential = New-Object System.Management.Automation.PSCredential ($AdUserManagerUpn, $AdUserManagerPss)

# Sets up Credentials for Freshservice API
Write-Information "Building Freshservice Credential Object"
$FreshserviceApiKey = $env:FreshserviceApiKey
$FreshserviceApiPss = 'x' | ConvertTo-SecureString -AsPlainText -Force
$FsCredential = New-Object System.Management.Automation.PSCredential ($FreshserviceApiKey, $FreshserviceApiPss)
$FreshserviceDomain = ($env:FreshserviceDomain)

# Rewrites all user-provided values to remove whitespace
$ContractorRequest.givenName = ($ContractorRequest.givenName).Trim()
$ContractorRequest.surname = ($ContractorRequest.surname).Trim()
$ContractorRequest.jobTitle = ($ContractorRequest.jobTitle).Trim()
$ContractorRequest.company = ($ContractorRequest.company).Trim()

# Sets up DisplayName to use Contractor format
$ContractorRequest.displayName = $ContractorRequest.givenName + ' ' + $ContractorRequest.surname + ' (CTR)'
Write-Information "Determined preferred displayName to be: $($ContractorRequest.displayName)"

# Determines Preferred sAMAccountName
$BaseSAMAccountName = "$($ContractorRequest.givenName).$($ContractorRequest.surname)".ToLower()
If ($BaseSAMAccountName.Length -gt 16)
    {$ContractorRequest.sAMAccountName = ($BaseSAMAccountName.Substring(0,16)) + '.ctr' }
Else
    {$ContractorRequest.sAMAccountName = $BaseSAMAccountName + '.ctr'}
Write-Information "Determined preferred sAMAccountName to be: $($ContractorRequest.sAMAccountName)"

# Creates UserPrincipalName --- TODO: Remove Explicit company reference
$ContractorRequest.userPrincipalName = ("$($ContractorRequest.givenName).$($ContractorRequest.surname)" + '.ctr@contoso.com').ToLower()
Write-Information "Determined preferred userPrincipalName to be: $($ContractorRequest.userPrincipalName)"

# Converts Date/Time String into AD Readable Format
$AccountExpirationDate = Get-Date $ContractorRequest.accountExpirationDate
Write-Information "Determined provided Expiration Date to be: $($ContractorRequest.AccountExpirationDate)"

# Generate Unique Employee ID by cutting up a GUID. This isn't pretty but it should be unique. Probably. There's a better way of doing this, I'm sure.
[GUID]$Guid = New-Guid | Select -Expand Guid
$GuidBase64 = [System.Convert]::ToBase64String($Guid.ToByteArray())
$ContractorRequest.employeeId = $GuidBase64.Substring(0,16)
Write-Information "Generated employeeId as: $($ContractorRequest.employeeId)"

# Generates a password as plaintext using custom function.
$ContractorRequest.accountPassword = New-SecurePassword
Write-Information "Generated Password as: $($ContractorRequest.accountPassword)"

# Builds a PS Session to the PAW --- TODO: Should make the IP address a variable and add redundancy.
$usermanagementsession = New-PSSession -ComputerName '127.0.0.1' -Credential $AdCredential -UseSSL -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck)
Write-Information "Created PSRemoting session on provided PAW."

#########################################################################################################################################
#                                                                                                                                       #
#                                                        SECTION 3 - ONBOARDING                                                         #
#                                                                                                                                       #
#########################################################################################################################################

# Creates the user account
####################################################################################################################################################
$Output = Invoke-Command -Session $usermanagementsession -ScriptBlock {

# Recreates Contractor Request Object within Remote Session
$ContractorRequest = $using:ContractorRequest
Write-Information "Imported Onboarding user object into PSRemoting session."

# Converts Password to Secure String
$PasswordSecureString = $ContractorRequest.accountPassword | ConvertTo-SecureString -AsPlaintext -Force
Write-Information "Converted Password into SecureString."

# Determines if the user already exists in the directory. If so, determines a new UPN and SAM AccountName
Write-Information "Checking to see if a user with the same sAMAccountName or userPrincipalName already exists."
$IncrementValue = 1
$TestUserExists = Get-ADUser -Filter * -Properties description -Credential $using:AdCredential | Where-Object { $_.samaccountname -eq $ContractorRequest.sAMAccountName -or $_.username -eq $ContractorRequest.userPrincipalName }
If ($TestUserExists.description -eq $ContractorRequest.ticket)
    {
    Write-Information "User already created. Aborting..."
    Return "ABORT"
    }
Else 
{
while ($TestUserExists)
    {
    Write-Information "Username already exists. Trying to append $IncrementValue"
    # Increments the SamAcountName - it should be noted this will only allow for nine people of the same name. Possibly need better logic
    $ContractorRequest.samaccountname = "$($ContractorRequest.givenName).$($ContractorRequest.surname)".ToLower()
    If ($ContractorRequest.samaccountname.Length -gt 15)
    {$ContractorRequest.samaccountname = $ContractorRequest.samaccountname.Substring(0,15) + $IncrementValue + '.ctr'}

    # Creates UserPrincipalName --- TODO: Remove Explicit company reference
    $ContractorRequest.userPrincipalName = ("$($ContractorRequest.givenName).$($ContractorRequest.surname)" + $IncrementValue + '.ctr@contoso.com').ToLower()

    # Increments Useraccount value and and retests to see if there is still a collision
    $IncrementValue++
    $TestUserExists = Get-ADUser -Filter * -Credential $using:AdCredential | Where-Object { $_.samaccountname -eq $samaccountname -or $_.username -eq $userprincipalname}
    }

# Sets email address for commercial access - might be able to deprecate soon.
$AdMail = ($ContractorRequest.userPrincipalName).replace("contoso.com","contoso.global")
Write-Information "Determined Contractor's email as $AdMail" 

# Gets Manager GUID and Department to set for contractor
$AdManager = get-aduser -filter * -Properties department -Credential $using:AdCredential | Where-Object Name -eq $ContractorRequest.manager 

New-ADUser `
    -Name $ContractorRequest.displayName `
    -DisplayName $ContractorRequest.displayName `
    -GivenName $ContractorRequest.givenName `
    -Surname $ContractorRequest.surname `
    `
    -SamAccountName $ContractorRequest.sAMAccountName `
    -UserPrincipalName $ContractorRequest.userPrincipalName `
    -Enabled $true `
    -AccountExpirationDate $ContractorRequest.accountExpirationDate `
    -AccountPassword $PasswordSecureString `
    -ChangePasswordAtLogon $true `
    `
    -EmployeeID $ContractorRequest.employeeId `
    -EmployeeNumber $ContractorRequest.employeeId `
    -Title $ContractorRequest.jobTitle `
    -Manager $AdManager.ObjectGuid `
    -Department $AdManager.Department `
    -Description $ContractorRequest.ticket `
    -EmailAddress $AdMail `
    -Credential $using:AdCredential `
    -Path $using:AdOuPath

Return $ContractorRequest.userPrincipalName
}
}
Write-Host $Output

#########################################################################################################################################
#                                                                                                                                       #
#                                                      SECTION 4 - TRANSMIT CREDENTIALS                                                 #
#                                                                                                                                       #
#########################################################################################################################################

# Escapes if not needed
If ($Output -eq "ABORT")
    {
    Exit
    }

# Obtains MS Graph token. This is used to send the email.
Write-Information "Obtaining Access Token for Microsoft Graph"
$Token = New-MsGraphAccessToken `
    -TenantId $env:MsGraphTenantId `
    -ClientId $env:MsGraphClientId `
    -ClientSecret $env:MsGraphClientSecret


# Sets up Variables so they don't have be be escaped. Those based on Request Object come from a webhook, environment variables are stored in the function.
$ToEmail = $ContractorRequest.externalemail
$ToName = $ContractorRequest.givenName + ' ' + $ContractorRequest.surname
$SenderGuid = $env:MsGraphEmailSenderId
$PayloadUsername = $Output
$PayloadPassword = $ContractorRequest.accountPassword
$Ticket = $fsticket

# Sets up Message Body to send message
$WelcomeMessage = "Hi $ToName, `
<br><br> `
Thank you for being a part of Contoso! We are happy to have you on the team. `
In order to get you up and running as quickly as possible, please reference the below items and reach out to the ServiceDesk with questions. Our contact information is at the bottom of this email. `
<br><br> `
<b>Logging In:</b><br> `
You will receive an encrypted email shortly which contains your Contoso username and password. You can follow the guide in the link below to open the email. Since Contoso uses Single Sign On for most of our systems, this is one of the few passwords you will need to remember here.<br> `
If you use Gmail, click here. https://contoso.freshservice.com/support/solutions/articles/17000029506<br> `
If you use Outlook or any other provider, click here. https://contoso.freshservice.com/support/solutions/articles/17000029511 `
<br><br> `
<b>Your token:</b><br> `
In the near future you will receive a token which is a hardware device you can attach to your keychain that generates random numbers when you press the button. Contoso requires the use of this token for certain actions, systems, and when we detect suspicious activity. You can follow the guide below for more information and instructions for testing the token.<br> `
https://contoso.freshservice.com/support/solutions/articles/55555555555 `
<br> `
<br> `
We look forward to working with you. Once again, welcome to Contoso. `
<br> `
<br> `
--- `
<br> `
IT ServiceDesk Team<br> `
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
Your Contoso Credentials are below: `
<br><br> `
<b>Username:</b><br> `
$PayloadUsername `
<br><br> `
<b>Password:</b><br> `
$PayloadPassword `
<br><br> `
For assistance in resetting your password, please visit the following link: <br> `
https://contoso.freshservice.com/support/solutions/articles/55555555555 `
<br> `
<br> `
Please test these credentials, and set your password as soon as possible. Note that some of your accounts may not be available until your start date. `
<br> `
<br> `
--- `
<br> `
IT ServiceDesk Team<br> `
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


#########################################################################################################################################
#                                                                                                                                       #
#                                                          SECTION 4 - CLEANUP                                                          #
#                                                                                                                                       #
#########################################################################################################################################

# Creates post content for updating the ticket in Freshservice
$TicketPostContent = @"
{
  "helpdesk_note": {
    "body":"The account for $($ContractorRequest.displayName) has been created. \n \n Username: \n $Output \n  This request is now complete. If you have not already, please provide a shipping address for this user's OTP Token.",
    "private":false
  }
}
"@

# Sends ticket update to freshservice
Invoke-RestMethod `
    -Uri "$FreshserviceDomain/helpdesk/tickets/$fsticket/conversations/note.json" `
    -Method Post `
    -Authentication Basic `
    -Credential $FsCredential `
    -ContentType 'application/json' `
    -Body $TicketPostContent
