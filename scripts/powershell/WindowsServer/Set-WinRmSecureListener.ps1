<#
Author: @garrett-wood
Purpose: Registers a custom Certificate to be served up by the WinRM Server. Often used if you don't use AD CS as your CA.
Requirements: A valid TLS Server certificate
Usage: Run this script and it should automatically identify the cert installed by your specified issuer with the latest expiration date. 
#>

# Be sure to change the Issuer to match the Issuer DN of your CA.
$IssuerDistinguishedName = "CN=Contoso Issuing CA, OU=Certification Authorities, O=Contoso, C=US"

# Gets the Computers name and domain name through WMI. We only care about the FQDN
$computerSystemWmi = Get-WmiObject Win32_ComputerSystem
$computerCertificateFqdn = [String]::Concat($computerSystemWmi.name,'.',$computerSystemWmi.domain)

# Gets the Cert issued for the hostname for SSLServerAuthentication. Uses the last one to expire that's valid for SSL authentication by that issuer
$pkiCert = (Get-ChildItem Cert:\LocalMachine\My\ `
    -SSLServerAuthentication `
    -DnsName $computerCertificateFqdn `
    | Where-Object Issuer -eq $IssuerDistinguishedName `
    | Sort-Object NotAfter -Descending)[0]

# Builds lists of arguments to call with WinRM. This was the least likely to cause errors after testing.
$winrmArgs =  [String]::Concat('create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="',$computerCertificateFqdn,'";CertificateThumbprint="',$pkiCert.Thumbprint,'"}')

# Starts a seperate process with proper encoding
Start-Process winrm -ArgumentList $winrmArgs

# Verifies the listener was successfully created
winrm enumerate winrm/config/listener
