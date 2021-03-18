  
<#
Author: @garrett-wood
Purpose: Registers a custom Certificate to be served up by the RDP Client. Often used if you don't use AD CS as your CA.
Requirements: A valid service auth certificate
Usage: This script will automatically request a certificate using your FQDN with the Client and Server Auth EKUs. If you need custom OID's, add them.
The output in the PS Windows will be the CSR. Give that to your PKI team, or submit to the CA yourself as org policies require.
#>

$CertName = ([System.Net.Dns]::GetHostByName(($env:computerName)).HostName)
$CSRPath = [environment]::getfolderpath("desktop") + "\" + $CertName + ".csr.txt"
$INFPath = [environment]::getfolderpath("desktop") + "\" + $CertName + ".inf"
$Signature = '$Windows NT$' 
 
 
$INF =
@"
[Version]
Signature= "$Signature" 
 
[NewRequest]
Subject = "CN=$CertName"
KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0
 
[EnhancedKeyUsageExtension]
 
OID=1.3.6.1.5.5.7.3.1
OID=1.3.6.1.5.5.7.3.2

[Extensions]
2.5.29.17 = "{text}" ; SAN - Subject Alternative Name
_continue_ = "dns=$CertName&"
"@
 
$INF | out-file -filepath $INFPath -force
certreq -new $INFPath $CSRPath

Write-Host "CSR Content Below:"
Write-Host " "
Get-Content $CSRPath
Write-Host " "

Remove-Item $INFPath
Remove-Item $CSRPath
