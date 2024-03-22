# Data Collection Rules assignment
### DeployReady - Assign DCR.json
-  This is a DeployIfNotExists policy that assigns the Data Collection Rules to a specific scope.
- It is filtered by the ImageId being used for the Virtual Machine or Virtual Machine Scale set.
- It has an evaluationPolicy of PT0M (immediate).
- It requires a user assigned managed identity with the RBAC roles defined below

# Data Collection Endpoint
### DeployReady - Assign DCE - MultiRegion.json 
-  This is a a DeployIfNotExists policy that assigns the appropiate Data Collection Endpoint to a specific scope based on the location/region.

- It is filtered by the ImageId being used for the Virtual Machine or Virtual Machine Scale set.

- It has an evaluationPolicy of PT0M (immediate).

- It requires a user assigned managed identity with the RBAC roles defined below

## Permissions required for the User Assigned Managed Identity for the DeployIfNotExists policies
Scope|Roles
---|---
Resource Group or Subscription of VM resources | Monitoring Contributor, Log Analytics Contributor
Resource Group of Data Collection Rules and Endpoints | Monitoring Contributor

# Azure Monitor Agent Extension deployment for VMSS
### DeployReady - VMSS Append Policy for AMA Extension.json

-  This is an Append policy that includes the Azure Monitor Agent extension when a VMSS is created or updated.
- It is filtered by the ImageId being used for the Virtual Machine or Virtual Machine Scale set.
- It does not have any permission requirements.