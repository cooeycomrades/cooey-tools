# Overview

The Firefox policies are extremely well documented and also located in Github. Please reference those for the latest information. 

# Process

1. Import the ADMX Files into Intune using the standard process as shown in the table below. The files are in this folder in the repo.

| Name                               | OMA-URI                                                                                                 | Data type |
|------------------------------------|---------------------------------------------------------------------------------------------------------|-----------|
| firefox.admx | `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/Firefox/Policy/FirefoxAdmx` | String    |

2. From here, you should stop and apply the policy to some devices. Verify you succeed, and see the values in the Registry before you continue.

3. Add the policies you need to. The below are a few examples. You would need to copy the value of the appropriate .xml file in this folder to the Value of the OMA-URI setting for the change to take affect. Again, it's highly recommended to consult Mozilla's documentation on this subject.
  
| Name                             | OMA-URI                                                                                                              | Data type |
|----------------------------------|----------------------------------------------------------------------------------------------------------------------|-----------|
| DisableBuiltinPDFViewer            | `./Device/Vendor/MSFT/Policy/Config/Firefox~Policy~firefox/DisableBuiltinPDFViewer`               | String    |
| ImportEnterpriseRoots            | `./Device/Vendor/MSFT/Policy/Config/Firefox~Policy~firefox~Certificates/Certificates_ImportEnterpriseRoots`               | String    |
| ExtensionSettings            | `./Device/Vendor/MSFT/Policy/Config/Firefox~Policy~firefox~Extensions/ExtensionSettings`               | String    |
