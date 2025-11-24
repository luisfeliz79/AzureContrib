# Steps for performing the RBAC Configuration

## Prerequisites:
- Azure PowerShell module installed.
- Global Administrator account in the Azure AD tenant.
- Global Administrator account must have "Access management for Azure resources" enabled.
- The Tenant ID of the Azure AD tenant
- The Object ID of an EntraID Group or User account


## Steps:

1) For the Global Administrator account, temporarily enable "Access management for Azure resources" in the Azure AD tenant.

    - In the Azure portal, navigate to "Azure Active Directory" > "Properties".
    - Set "Access management for Azure resources" to "Yes" and save the changes.

2) Via a PowerShell window, 
Connect to Azure with a Global Administrator account in the Azure AD tenant.
    ```powershell
    $TenantID = "<tenant id>"

    Connect-AzAccount -Tenant $TenantID  -UseDeviceAuthentication -Force
    ```


3) Configure RBAC for the Microsoft.AppInsights Provider
    ```powershell
    $UserObjectID = "<the object id of a grou or user that will manage the monitored objects>"

    New-AzRoleAssignment -Scope '/providers/Microsoft.Insights' -RoleDefinitionName 'Monitored Objects Contributor' -ObjectId $UserObjectID
    ```

4) LogOff Azure PowerShell
    ```powershell
    $CurrentUser=(Get-AzAdUser -SignedIn).userPrincipalName
    Logout-AzAccount -Username $CurrentUser
    ```

5) Remove the temporary "Access management for Azure resources" from the Global Administrator account.

    **Note**: If you are currently logged in as the Global Administrator, you may need to log out before you can process this change.

    - In the Azure portal, navigate to "Azure Active Directory" > "Properties".
    - Set "Access management for Azure resources" to "No" and save the changes.