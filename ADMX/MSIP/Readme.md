# Purpose
Sets the value for the MSIP/AIP client using Intune, with full compliance visibility

# Usage 
Both of these files must be uploaded to Microsoft Intune using a Custom policy, which will allow you to directly reference an OMA-URI. You can use the same Custom policy to deploy both settings. Name it what you wish. This has been updated so only the 'new' Unified Client Registry value can be changed. If you're still using the older version of this, please update.

## Intune

1. Create a new Custom Policy in Intune.
2. Create a new OMA-URI Setting. I named mine `MSIP.admx`
3. for the OMA-URI, type: `./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/MSIP/Policy/MSIP.Admx`
4. For the Value, paste in the contents of the MSIP.admx file as a String. Set the description if desired.
5. Add a second new OMA-URI Setting called `CloudEnvType`
6. For the OMA-URI, type: `./Device/Vendor/MSFT/Policy/Config/MSIP~Policy~CloudEnvironment/CloudEnvType`
7. For the Value, paste in the Contents of the CloudEnvType.xml file, and substitute another value for the '2' if you aren't in GCCH.
8. Save all settings and deploy to your test group, then to prod.

## Group Policy
1. Download and save the `MIP_Cloud.admx` and `MIP_Cloud.adml`files onto your local workstation
2. Copy those file to wherever you copy PolicyDefinitions to your domain, with the .adml file going under the en-US subdirectory
3. Open Group Policy Management on a machine that can reference the policy store that has those files propagated.
4. Find the value under "Microsoft Information Protection" and set the Cloud Environment Type to your assigned tenant type.
5. Test the Policy in a test forest, domain, OU, or security group then send to protection.

# Author
@garrett-wood

# References
https://somedownti.me/2020/06/02/import-administrative-templates-admx-into-intune/  
https://docs.microsoft.com/en-us/enterprise-mobility-security/solutions/ems-aip-premium-govt-service-description  
https://4sysops.com/archives/how-to-create-an-admx-template/#admx-template-structure
