<#
Author: @garrett-wood

Purpose:
This script can be used to sign code procedurally. It uses the Az module to aquire an identity with permissions in Azure, then gets
the access token that's used by the Sign Tool. It is currently setup to be agnostic to cloud location eg. US Gov vs Commercial

Requirements:
Az PowerShell Module (https://www.powershellgallery.com/packages/Az/6.0.0)
AzureSignTool Nuget Package (https://www.nuget.org/packages/AzureSignTool/)
.NET Framework 2.1.0 (https://aka.ms/dotnet-core-applaunch?framework=Microsoft.NETCore.App&framework_version=2.1.0&arch=x64&rid=win10-x64)

Instructions:
Take the two variables immediately below this description and fill them with the right values for your key vault. Once you've done so, I
strongly recommend you test this by signing this script itself. You can swap out the timestamp authority to your choice, it doesn't matter
as long as it has RFC 3161 compliance. Note that you will need to assign permissions into the key vault in order to use this. I recommend
that you visit the github page for Azure Key Vault to determine what is necessary.
#>

# This is the name of your keyvault. Recommend all lower case.
$VaultName = 'contoso-codesigning-kv'
# This is the name of the cert within your vault.
$VaultCert = 'Contoso-EV-CodeSignging-Cert'
# This is the authority you use for timestamping. Always timestamp your code unless you have a known, specific reason to not do so.
$Timestamp = 'http://timestamp.entrust.net/rfc3161ts2'


# Creates dialog box to select file
$initialDirectory = [environment]::getfolderpath("Desktop")
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "Executable Files|*.ps1;*.dll;*.msi;*.exe;*.appx;*.appxbundle"
    $OpenFileDialog.ShowDialog() | Out-Null
$FilePath = $OpenFileDialog.FileName

# Connects to Azure with said credential, and uses authentication session to obtain key vault token
$TenantId = (Get-ItemProperty (Get-ChildItem "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo").Name.Replace("HKEY_LOCAL_MACHINE","HKLM:")).TenantId
$WellKnown = Invoke-RestMethod "https://login.microsoftonline.com/$TenantId/v2.0/.well-known/openid-configuration"
$AzEnvironment = Get-AzEnvironment | Where-Object ActiveDirectoryAuthority -like "*$($WellKnown.cloud_instance_name)*"
$KeyVaultSuffix = $AzEnvironment.AzureKeyVaultServiceEndpointResourceId.Split('//')[2]
Connect-AzAccount -Environment $AzEnvironment.Name
$Token = Get-AzAccessToken -ResourceTypeName KeyVault
Disconnect-AzAccount

# Signs Binaries
AzureSignTool.exe sign `
    --azure-key-vault-url ("https://" + $VaultName + ".$KeyVaultSuffix/") `
    --azure-key-vault-accesstoken $Token.Token `
    --azure-key-vault-certificate $VaultCert `
    --timestamp-rfc3161 $Timestamp `
    --verbose `
    $FilePath
