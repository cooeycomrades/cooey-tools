# Overview
There is a known issue with HID ActivClient and how it interacts with Microsoft Information Protection in Microsoft Outlook. Fortunately, there's a simple enough fix for this,
which involves simply removing the permissions for `OUTLOOK.EXE` to access the PIN Caching Subsystem for ActivClient. Fortunately, we don't need to entirely removing the PIN
Caching function to resolve this and the removal can be done manually. This can be resolved by setting a single entry in the Registry. The Key in question is located in `HKLM:\SOFTWARE\Policies\HID Global\SharedStore\Authentication\ExcludeList`. The children of this key should be string (`REG_SZ`) values with the same name and value. In the case of Outlook, you'd follow the format listed in the `PINCachingExcludeList.xml` file that is available in this folder. Fortunately, the US Government has already released the necessary ADMX files in their public repo [here](https://github.com/nsacyber/Windows-Secure-Host-Baseline/tree/master/ActivClient/Group%20Policy%20Templates), with the appropriate usage rights so we'll go right ahead and take advantage of that.

# Process

1. Import the ADMX Files into Intune using the standard process as shown in the table below. The files are in this folder in the repo.

| Name                               | OMA-URI                                                                                                 | Data type |
|------------------------------------|---------------------------------------------------------------------------------------------------------|-----------|
| HIDGlobal.AdvancedDiagnostics.admx | `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/HIDGlobal/Policy/HIDGlobal.AdvancedDiagnostics` | String    |
| HIDGlobal.Logging.admx             | `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/HIDGlobal/Policy/HIDGlobal.Logging`             | String    |
| HIDGlobal.ActivClient0.admx        | `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/HIDGlobal/Policy/HIDGlobal.ActivClient0`        | String    |
| HIDGlobal.ActivClient1.admx        | `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/HIDGlobal/Policy/HIDGlobal.ActivClient1`        | String    |

2. From here, you should stop and apply the policy to some devices. Verify you succeed, and see the values in the Registry before you continue.

3. Add the policies you need to. The below are a few examples. The PINCachingExcludeList is what will fix the Outlook issue, and exempting the WHfB from the useable readers should fix the issue with being unable to enroll IdenTrust certificates is taken care of with the ReaderBlackList policy. You can find these files in this same folder using the <name>.xml naming convention.
  
| Name                             | OMA-URI                                                                                                              | Data type |
|----------------------------------|----------------------------------------------------------------------------------------------------------------------|-----------|
| PINCachingExcludeList            | `./Device/Vendor/MSFT/Policy/Config/HIDGlobal~Policy~CAT_ActivClient~PinCaching/PINCachingExcludeList`               | String    |
| TimeOutToClearCache              | `./Device/Vendor/MSFT/Policy/Config/HIDGlobal~Policy~CAT_ActivClient~PinCaching/TimeOutToClearCache`                 | String    |
| HidePublishToGal                 | `./Device/Vendor/MSFT/Policy/Config/HIDGlobal~Policy~CAT_ActivClient~UserConsole/HidePublishToGal`                   | String    |
| AutoConfigEFS                    | `./Device/Vendor/MSFT/Policy/Config/HIDGlobal~Policy~CAT_ActivClient~CertificateAvailability/AutoConfigEFS`          | String    |
| UnlockCardContactTelephoneNumber | `./Device/Vendor/MSFT/Policy/Config/HIDGlobal~Policy~CAT_ActivClient~PinManagement/UnlockCardContactTelephoneNumber` | String    |
| ReaderBlackList                  | `./Device/Vendor/MSFT/Policy/Config/HIDGlobal~Policy~CAT_ActivClient~SmartCardReaders/ReaderBlackList`               | String    |

# Details:

### PINCachingExcludeList
This should be used if you want to avoid the S/MIME and MS AIP incompatibility issue. This is probably the reason most of you are here.

### TimeOutToClearCache
This should be used to increase or further drop the timeout for the PIN Caching. Default is 15 minutes. Values are 0 (disabled) to 9999 (infinite) which you really shouldn't use.
  
### HidePublishToGal
Are you using Azure AD-joined devices? ActivClient's Publish to GAL button will cause an error. Don't want the helpdesk tickets? Use this one.
  
### AutoConfigEFS
ActivClient will use the default cert (if it is capable) for setting up EFS. You probably don't want that.

### UnlockCardContactTelephoneNumber
This will set the contact number it displays for users when they ask for help because their card is locked. You probably want your helpdesk here.

### ReaderBlackList
Add WHfB, YubiKey or whatever else you don't want handled by ActivClient Here. Implied wildcard on the end. Case-Sensitive.


## Author
@garrett-wood
