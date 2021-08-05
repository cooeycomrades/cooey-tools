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
Contains the values required to configure the Chrome [ExtensionInstallForceList](https://chromeenterprise.google/policies/?policy=ExtensionInstallForcelist) so that the Windows 10 Accounts and Microsoft Defender extensions are automatically installed from the Chrome public marketplace.

The format of the data within the file follows standard conventions and starts with an `<enabled/>` node to enable the settings. That is followed by a `<data>` node to list out the settings value. The format for the value property is `<incrementing number>&#xF000;<Chrome Extension ID>;<Update URL>`. In this specific file we are installing two extensions, the first one with the incrementing number of 1 is the [Windows Accounts](https://chrome.google.com/webstore/detail/windows-10-accounts/ppnbnpeolgkicgegkbkbjmhlideopiji?hl=en) extension which has an ID of `ppnbnpeolgkicgegkbkbjmhlideopiji`. The second extension is the [Microsoft Defender](https://chrome.google.com/webstore/detail/microsoft-defender-browse/bkbeeeffjjeopflfhgeknacdieedcoml?hl=en) extension which has an ID of `bkbeeeffjjeopflfhgeknacdieedcoml`. The update URL is a common URL if installing from the public Chrome Webstore `https://clients2.google.com/service/update2/crx`. 

The settings within the MicrosoftExtensions.xml file are generic, they do not require modification and can be deployed as is to tenants within Commercial, GCC and GCC-H in order to ensure the Windows 10 Accounts extension is installed so users using Chrome will support device based conditional access policies

This sample includes Microsoft specific extensions but you can modify the `<data>` node to include additional extensions to install through the following process. 

1) Open the extension within the Chrome webstore to discover the extension ID
2) Review the browser URL for the Extension ID 
Below is the Windows 10 Accounts URL, the bold text is the Extension ID
https://chrome.google.com/webstore/detail/microsoft-defender-browse/**bkbeeeffjjeopflfhgeknacdieedcoml**?hl=en. 
3) Append `&#xF000;3&#xF000;<extensionid>;https://clients2.google.com/service/update2/crx` to the value replacing `<extensionid>` with the ID you retrieve from the step 2
4) You can continue this to add additional ones increasing the 3 to 4 and so on as you add additional extensions


