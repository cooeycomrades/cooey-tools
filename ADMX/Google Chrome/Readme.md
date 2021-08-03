# Overview

Similar to an on-premises Active Directory environment. Chrome published ADMX policies can be imported and utilized to manage Chrome settings through Microsoft Endpoint Manager. 

While there are a number of configurations that can be done this document will outline importing the ADMX info and configuration settings required for Chrome to be compatible with Azure AD conditional access policies. A preview STIG in Endpoint Manager json format has been published and should be referred to for secure configurations https://public.cyber.mil/stigs/gpo/. 

# Process

1. Import the ADMX Files into Intune using the standard process as shown in the table below. The files are in this folder in the repo.

| Name                               | OMA-URI                                                                                                 | Data type |
|------------------------------------|---------------------------------------------------------------------------------------------------------|-----------|
| chrome.admx | `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/Chrome/Policy/ChromeADMX` | String    |

2. From here, you should stop and apply the policy to some devices. Verify you succeed, and see the values in the Registry before you continue.

3. Add the policies you need to. The below are a few examples. The ExtensionInstallForceList will install extensions required for device based conditional access policies within Azure AD. 
  
| Name                             | OMA-URI                                                                                                              | Data type |
|----------------------------------|----------------------------------------------------------------------------------------------------------------------|-----------|
| MicrosoftExtensions            | `./Device/Vendor/MSFT/Policy/Config/Chrome~Policy~googlechrome~Extensions/ExtensionInstallForcelist`               | String    |


# Details:

### MicrosoftExtensions
Configures the force install list for Google Chrome in order to install the Microsoft Accounts extension and Microsoft Defender extension. The Microsoft Accounts extension is required for Google Chrome to report the device state to Azure AD to be used for conditional access policies. More information can be found [here](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/concept-conditional-access-conditions#chrome-support)


## Author
@alally
