# Overview
There is a known issue with HID ActivClient and how it interacts with Microsoft Information Protection in Microsoft Outlook. Fortunately, there's a simple enough fix for this,
which involves simply removing the permissions for `OUTLOOK.EXE` to access the PIN Caching Subsystem for ActivClient. Fortunately, we don't need to entirely removing the PIN
Caching function to resolve this and the removal can be done manually. This can be resolved by setting a single entry in the Registry. The Key in question is located in `HKLM:\SOFTWARE\Policies\HID Global\SharedStore\Authentication\ExcludeList`. The children of this key should be string (`REG_SZ`) values with the same name and value. In the case of Outlook, you'd follow the format listed in the `PINCachingExcludeList.xml` file that is available in this folder. Fortunately, the US Government has already released the necessary ADMX files in their public repo [here](https://github.com/nsacyber/Windows-Secure-Host-Baseline/tree/master/ActivClient/Group%20Policy%20Templates), with the appropriate usage rights so we'll go right ahead and take advantage of that.

# Process

1. Import the ADMX Files into Intune using the standard process as shown in the table below. For the ActivClient 0 and 1 files, you'll need to split the file in two otherwise Intune won't ingest all the policiies. I don't know why. It's weird. Just split the file at the Pin section by cutting out the policies. Ensure to accurately remove the entirety of the policies as improperly removing only part of the policy will catostrophically fail, and it won't tell you why.

| Name                               | OMA-URI                                                                                                 | Data type |
|------------------------------------|---------------------------------------------------------------------------------------------------------|-----------|
| HIDGlobal.AdvancedDiagnostics.admx | `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/HIDGlobal/Policy/HIDGlobal.AdvancedDiagnostics` | String    |
| HIDGlobal.Logging.admx             | `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/HIDGlobal/Policy/HIDGlobal.Logging`             | String    |
| HIDGlobal.ActivClient0.admx        | `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/HIDGlobal/Policy/HIDGlobal.ActivClient0`        | String    |
| HIDGlobal.ActivClient1.admx        | `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/HIDGlobal/Policy/HIDGlobal.ActivClient1`        | String    |

2. From here, you should stop and apply the policy to some devices. Verify you succeed, and see the values in the Registry before you continue.

3. Add the policies you need to. The below are a few examples. The PINCachingExcludeList is what will fix the Outlook issue.





# Additional Remarks
On the topic of ActivClient, there are some known issues with Windows Hellof for Business while attempting to enroll for a certificate. Specifically, ActivClient detects two smartcards are inserted (the real one and the Virtual one) and then freaks out. It *may* be possible to use the Reader Blacklist setting to to address this by prevening ActivClient from seeting WHfB, but that this has not yet been tested. This **untested** policy is located in `ReaderBlackList.xml` which would need to be deployed to `./Device/Vendor/MSFT/Policy/Config/HIDGlobal~Policy~CAT_ActivClient~SmartCardReaders/ReaderBlackList` using the same assumptions as above.

### Author
@garrett-wood
