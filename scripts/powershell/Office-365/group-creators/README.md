# Office 365 Scripts

## Group Creators Script:
This script was originally on Microsoft's website. I just modifed one line to make it work with GCC High

### Features:
Prevents anyone except members of the groups listed below or members of the specified security group within the script to create Microsoft 365 Groups. This will allow prevent user's outside of this group from creating Teams or SharePoint sites. 

#### Users in the following groups will still be able to create Microsoft/Office 365 Groups even after the script has been run: 
- Exchange Administrator: Exchange Admin center, Azure AD
- Global Admins: Exchange Admin center, Azure AD, Teams Admin center, SharePoint Admin center
- Partner Tier 1 Support: Microsoft 365 Admin center, Exchange Admin center, Azure AD
- Partner Tier 2 Support: Microsoft 365 Admin center, Exchange Admin center, Azure AD
- Directory Writers: Azure AD
- SharePoint Administrator: SharePoint Admin center, Azure AD
- Teams Service Administrator: Teams Admin center, Azure AD
- User Management Administrator: Microsoft 365 Admin center, Azure AD

### Instructions
1. Open PowerShell on a Windows workstation
2. Install the Azure Active Directory Preview module by running Install-Module AzureADPreview
3. Open the GroupCreators.ps1 file in a text editor and modify the value for $GroupName to be the name of the security group you created.
4. Within PowerShell navigate to the directory where the script is saved and run it. 
5. Test group creation with a user that should not have the privileges and see if the script worked. 

### Bugs: 
I have noticed one bug within my tenant after running this script which is you are no longer able to preperly create Teams from within the Teams Admin Center Web Portal. When a Team gets created it does not show up for the users added to it and is not searchable. You will either need to create your Team from within the Teams Desktop or Web Application or create the Team using PowerShell.

Link to original Microsoft Article: https://docs.microsoft.com/en-us/microsoft-365/solutions/manage-creation-of-groups?view=o365-worldwide
