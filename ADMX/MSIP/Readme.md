# Purpose
Sets the value for the MSIP/AIP client using Intune, with full compliance visibility

# Usage 
Both of these files must be uploaded to Microsoft Intune using a Custom policy, which will allow you to directly reference an OMA-URI.

You can use the same Custom policy to deploy both settings. Name it what you wish.

1. Create a new Custom Policy in Intune.
2. Create a new OMA-URI Setting. I named min MSIP.admx
3. for the OMA-URI, type: ./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/MSIP/Policy/MSIP.Admx
4. For the Value, paste in the contents of the MSIP.admx file as a String. Set the description if desired.
5. Add a second new OMA-URI Setting called "CloudEnvType"
6. For the OMA-URI, type: ./Device/Vendor/MSFT/Policy/Config/MSIP~Policy~CloudEnvironment/CloudEnvType
7. For the Value, paste in the Contents of the .xml file, and substitue another value for the '2' if you aren't in GCCH.
8. Save all settings and deploy to your test group, then to prod.

# Author
@garrett-wood

# References
https://somedownti.me/2020/06/02/import-administrative-templates-admx-into-intune/  
https://docs.microsoft.com/en-us/enterprise-mobility-security/solutions/ems-aip-premium-govt-service-description  
https://4sysops.com/archives/how-to-create-an-admx-template/#admx-template-structure
