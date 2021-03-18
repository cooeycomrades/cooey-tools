<#
Author: @garrett-wood
Purpose: Registers a custom Certificate to be served up by the RDP Client. Often used if you don't use AD CS as your CA.
Requirements: A valid service auth certificate
Usage: Run this script and it should automatically identify the cert installed by your specified issuer with the latest expiration date. 
Be sure to change the Issuer to match the Issuer DN of your CA.
#>

# Gets the Cert issued for the hostname for SSLServerAuthentication
$pkiCert = (Get-ChildItem Cert:\LocalMachine\My\ `
    -SSLServerAuthentication `
    -DnsName ([System.Net.Dns]::GetHostByName(($env:computerName)).HostName) `
    | Where-Object Issuer -eq "CN=Your Org Issuing CA, OU=Certification Authorities, O=Your Org, C=US" `
    | Sort-Object NotAfter -Descending)[0]

# Sets RDP to use that certificate for authentication
wmic /namespace:\\root\cimv2\TerminalServices PATH Win32_TSGeneralSetting Set SSLCertificateSHA1Hash=$($pkiCert.Thumbprint)
