# Office 365 Scripts

## Group Creators Script:
### Features:
Prevents anyone except Global Admins or members of the specified security group within the script to create Microsoft 365 Groups. This will allow prevent user's outside of this group from creating Teams or SharePoint sites. 

### Bugs: 
I have noticed one bug within my tenant after running this script which is you are no longer able to preperly create Teams from within the Teams Admin Center Web Portal. When a Team gets created it does not show up for the users added to it and is not searchable. You will either need to create Teams from within the Teams Desktop or Web Application or Create the Team using PowerShell.
