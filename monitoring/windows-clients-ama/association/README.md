### Azure Monitor Agent Association for Windows Clients

## Prerequisites
The setup account must be given the following RBAC permissions:
- Reader access to the Data Collection Rule(s) to be associated
- Monitored Objects Contributor role at the '/providers/Microsoft.Insights' scope. This requires a Global Administrator to assign.


The following tools are required:
- Azure PowerShell
- Helper functions script: [helper-functions.ps1](./helper-functions.ps1)


## RBAC Setup
```powershell

$TenantID = "<tenant id>" 
$UserObjectID = "<the object id of the setup account>"

Connect-AzAccount -Tenant $TenantID  -UseDeviceAuthentication -Force

# Assign the Monitored Objects Contributor role
New-AzRoleAssignment -Scope '/providers/Microsoft.Insights' -RoleDefinitionName 'Monitored Objects Contributor' -ObjectId $UserObjectID

# Assign Reader role to the DCR
$DcrResourceId = "/subscriptions/866ad786-dccd-4b7d-bfcf-bebeff55a41d/resourceGroups/rg-foundational/providers/Microsoft.Insights/dataCollectionRules/win-events-dcr"
New-AzRoleAssignment -Scope $DcrResourceId -RoleDefinitionName 'Reader' -ObjectId $UserObjectID

```

## Monitored Objects Configuration

```powershell

# Dot source the Helper functions
. .\helper-functions.ps1

# Set variables
$TenantID = "<tenant id>" #Your tenant ID
$AssociationName = "win-events-dcr" # Your choice
$DcrId = "/subscriptions/xxxxx/resourceGroups/xxxx/providers/Microsoft.Insights/dataCollectionRules/win-events-dcr"

# Connect to Azure
Connect-AzAccount -Tenant $TenantID  -UseDeviceAuthentication -Force


# List or Create the Monitored Object
List-MonitoredObjects -TenantId $TenantID     # Check for existing
Create-MonitoredObject -TenantId $TenantID    # Create it
List-MonitoredObjects -TenantId $TenantID     # Prove it exists now


# Associate a DCR  (Your account must have at least reader access to the DCR)
Add-MonitoredObjectDCRAssociation -TenantId $TenantID -associationName $AssociationName -DCRId $DcrId

# Optional - add more DCRs
#Add-MonitoredObjectDCRAssociation -TenantId $TenantID `
#   -associationName "another" `
#   -DCRId "/another/dcr/id"

List-MonitoredObjectsDCRAssociations -TenantID $TenantID


```