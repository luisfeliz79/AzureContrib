# AppServiceMaitenance
A script for rebooting multiple Azure Web apps, Slots, Azure Functions in sequence.

This script...
- Allows to specify a list of Apps (Resource IDs) to restart, on a text file.
- Will prompt to authenticate using Azure AD Device Code authentication
- Will check that the logged in account has appropiate access to perform the restarts
- Will validate each Resource ID and provide current Web app status
- Will ask to confirm before the restart

## Prepare the script
-  Click [here]() to review the script
-  Copy and paste into PowerShell ISE (powershell_ise)
-  Add or Modify the list of Supported RBAC Priviledge Roles to check for
-  Save the script

## Using it
- Prepare a text file using Notepad or similar editor
- Create a text file (ex. Using notepad) and add list of resource IDs for Azure Web apps, Web app slots, or Function Apps.  One per line.
- Run the script like this:

    ```powershell
    . ./AppServiceMaintenance.ps1
    Restart-WebApps -Path mylist.txt
    ```


