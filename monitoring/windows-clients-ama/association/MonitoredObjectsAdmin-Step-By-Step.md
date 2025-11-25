# Steps for Configuring Monitored Objects

## Prerequisites:
- An account that has been assigned the Monitored Objects Contributor role [via this process](./GlobalAdmin-Step-by-Step.md).
- The account should also have reader access to the Data Collection Rule(s) to be associated.
- The Resource ID of the Data Collection Rule Resource.
- The Tenant ID of the Azure AD tenant.
- Azure PowerShell module installed.
- The helper functions script: [helper-functions.ps1](./helper-functions.ps1)



## Steps:


1) Via a PowerShell window, 
Connect to Azure with the account that has been assigned the Monitored Objects Contributor role.
    ```powershell
    $TenantID = "<tenant id>"

    Connect-AzAccount -Tenant $TenantID  -UseDeviceAuthentication -Force

    #Note: If given a choice, choose any subscription from the list.

    ```

2) Define functions that will make the process easier.  Options:

    - Copy and paste the code from helper-functions.ps1 into your own script or PowerShell Window.

    -- or --
    - Dot source the helper-functions.ps1 file after saving it locally

    ```powershell
    . .\helper-functions.ps1


    # Note: If running on Windows, you may  need to configure the execution policy first:
    #Set-executionPolicy -ExecutionPolicy Bypass -Scope Process

    ```


3) Create the Monitored Object for the tenant.

    ```powershell

    Create-MonitoredObjects -TenantId $TenantID   

    ```


4) Associate the Data Collection Rule with the Monitored Object.

    ```powershell

    # Define needed variables

    $AssociationName = "<the name of the association, your choice>" 

    $DcrId = "<The resource ID of the DCR>"

    Add-MonitoredObjectsDCRAssociation -TenantId $TenantID -associationName $AssociationName -DCRId $DcrId
    ```


5) Verify the association.

    ```powershell
    List-MonitoredObjectsDCRAssociations -TenantID $TenantID
    ```