# Deployment Service Principal
This principal is used in combination with Terraform to deploy Azure Resources.
### For Azure Automation and Azure Arc Gateway
| Role Name | Purpose |
|-----------|---------|
| Automation Contributor | For automating tasks and managing resources |
| Managed Identity Contributor | For creating managed identities |
| Managed Identity Operator | For assigning managed identities to resources |
| Arc Gateway Manager | For managing Azure Arc gateways |
### For Azure Key Vault, Storage, and Log Analytics resources
| Role Name | Purpose |
|-----------|---------|
| Key Vault Contributor | For deploying Key Vaults |
| Key Vault Administrator | For full administrative access to Key Vaults |
| Storage Account Contributor | For deploying Storage accounts |
| Storage Blob Data Contributor | For read/write access to blobs |
| Log Analytics Contributor | For deploying Log Analytics Workspaces |

### For configuring Azure RBAC and role assignments
| Role Name | Purpose |
|-----------|---------|
| User Access Administrator | For managing role assignments and RBAC. This role can be scoped to the resource group and be further constrained |

# Arc Agent Onboarding Service Principal
This principal is used when running the Azure Arc onboarding script.
| Role Name | Purpose |
|-----------|---------|
| Azure Connected Machine Onboarding | For onboarding machines to Azure Arc |


# Arc Agents Administrators (for Operations)
This role can be added to a principal that can be used for ongoing management of Arc-enabled servers and extensions. This is optional and not required for the deployment or operation of the solution, but can be used to delegate management of Arc-enabled servers to a specific principal or group.
| Role Name | Purpose |
|-----------|---------|
| Azure Connected Machine Resource Administrator | For managing Arc-enabled servers and extensions |
