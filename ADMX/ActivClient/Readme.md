# Overview
There is a known issue with HID ActivClient and how it interacts with Microsoft Information Protection in Microsoft Outlook. Fortunately, there's a simple enough fix for this,
which involves simply removing the permissions for `OUTLOOK.EXE` to access the PIN Caching Subsystem for ActivClient. Fortunately, we don't need to entirely removing the PIN
Caching function to resolve this and the removal can be done manually. When you purchase ActivClient directly from HID, you actually gain access to the ADMX files that make this 
process easier, however the rights to distribute those files aren't granted so they cannot be distributed here. The process included below is my best effort to answer the issue
without encountering licensing or distribution issues.

# Process
This can be resolved by setting a single entry in the Registry. The Key in question is located in `HKLM:\SOFTWARE\Policies\HID Global\SharedStore\Authentication\ExcludeList`.
The children of this key should be string (`REG_SZ`) values with the same name and value. In the case of Outlook, you'd follow the format listed in the `PINCachingExcludeList.xml`
file that is available in this folder. This value would need to be committed to `./Device/Vendor/MSFT/Policy/Config/HIDGlobal~Policy~CAT_ActivClient~PinCaching/PINCachingExcludeList` if we can assume that the hypothetical file you'd have defining the ADMX side of the policy was located at `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/HIDGlobal/Policy/HIDGlobal.ActivClient1`. It would also need to have the appropriate major and minor cateogry information you can reference from the documentation.

# Additional Remarks
On the topic of ActivClient, there are some known issues with Windows Hellof for Business while attempting to enroll for a certificate. Specifically, ActivClient detects two smartcards are inserted (the real one and the Virtual one) and then freaks out. It *may* be possible to use the Reader Blacklist setting to to address this by prevening ActivClient from seeting WHfB, but that this has not yet been tested. This **untested** policy is located in `ReaderBlackList.xml` which would need to be deployed to `./Device/Vendor/MSFT/Policy/Config/HIDGlobal~Policy~CAT_ActivClient~SmartCardReaders/ReaderBlackList` using the same assumptions as above.

### Author
@garrett-wood
