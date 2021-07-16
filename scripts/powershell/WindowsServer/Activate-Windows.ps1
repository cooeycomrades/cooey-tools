<# 
Purpose:
Used to activate windows using motherboard installed license key when Windows fails to automatically
   
Usage:
Run as administrator
   
Author: @garrett-wood
#>

# Retrieves License Key from BIOS/UEFI
$LicenseKey = (Get-WmiObject SoftwareLicensingService).OA3xOriginalProductKey

# Installs Product Key
slmgr.vbs /ipk $LicenseKey

# Activates Windows
slmgr.vbs /ato
