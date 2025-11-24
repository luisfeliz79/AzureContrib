### Azure Monitor Agent Association for Windows Clients

## Prerequisites
The MonitoredObjects administrator account must be given the following RBAC permissions:

- Reader access to the Data Collection Rule(s) to be associated

- Monitored Objects Contributor role at the '/providers/Microsoft.Insights' scope. This requires a Global Administrator to assign.   To configure this role assignment, see the [RBAC Setup](#rbac-setup) section below.

The following tools are required:
- Azure PowerShell
- Helper functions script: [helper-functions.ps1](./helper-functions.ps1)



## RBAC Setup
To implement the required permissions, a Global Administrator account that has been granted Access Management for Azure resources access is required.  For more information on Root Level access, see https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin?tabs=azure-portal%2Centra-audit-logs.

<mark style="background-color: lightblue">Note: This elevated access is only needed to assign the Monitored Objects Contributor role at the root scope.  After that role assignment is complete, the elevated access should be removed.
</mark>

```powershell

$TenantID = "<tenant id>" 
$UserObjectID = "<the object id of the setup account>"

Connect-AzAccount -Tenant $TenantID  -UseDeviceAuthentication -Force

# Assign the Monitored Objects Contributor role
New-AzRoleAssignment -Scope '/providers/Microsoft.Insights' -RoleDefinitionName 'Monitored Objects Contributor' -ObjectId $UserObjectID

# Assign Reader role to the DCR (or the resource group or subscription containing the DCR)
$Scope = "/subscriptions/xxxxx/resourceGroups/xxxx/providers/Microsoft.Insights/dataCollectionRules/win-events-dcr"
New-AzRoleAssignment -Scope $Scope -RoleDefinitionName 'Reader' -ObjectId $UserObjectID

```

## Monitored Objects Configuration

```powershell

# Dot source the Helper powershell functions
# Feel free to incorporate into your own scripts
# It is best to copy the text code into your own file.
# If saved directly, you may run into Execution policy issues,
# which can be resolved like this for your current console session:
# Set-executionPolicy -ExecutionPolicy Bypass -Scope Process  # Windows Only
. .\helper-functions.ps1

# Set variables
$TenantID = "<tenant id>" #Your tenant ID
$AssociationName = "win-events-dcr" # Your choice
$DcrId = "/subscriptions/xxxxx/resourceGroups/xxxx/providers/Microsoft.Insights/dataCollectionRules/win-events-dcr"

# Connect to Azure
Connect-AzAccount -Tenant $TenantID  -UseDeviceAuthentication -Force


# List or Create the Monitored Object
List-MonitoredObjects -TenantId $TenantID     # Check for existing
Create-MonitoredObjects -TenantId $TenantID    # Create it
List-MonitoredObjects -TenantId $TenantID     # Prove it exists now


# Associate a DCR  (Your account must have at least reader access to the DCR)
Add-MonitoredObjectsDCRAssociation -TenantId $TenantID -associationName $AssociationName -DCRId $DcrId

# Optional - add more DCRs
# Add-MonitoredObjectsDCRAssociation -TenantId $TenantID `
#   -associationName "another" `
#   -DCRId "/another/dcr/id"

List-MonitoredObjectsDCRAssociations -TenantID $TenantID
```


## Cleaning up

```powershell
$TenantID = "<tenant id>" #Your tenant ID
$AssociationName = "win-events-dcr" # Your choice

# See existing Associations
List-MonitoredObjectsDCRAssociations -TenantID $TenantID

# Remove the DCR Association (do this multiple times, if multiple associations)
Remove-MonitoredObjectsDCRAssociation -TenantID $TenantID -associationName $AssociationName

# Remove the Monitored Object
Remove-MonitoredObjects -TenantId $TenantID

```




## References
- [Install the Azure Monitor Agent on Windows client devices by using the client installer](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-windows-client)

- [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin)



