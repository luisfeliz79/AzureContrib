# Azure Resources Deployment Service Principal
This service principal allows automated deployment of Azure resources with appropriate permissions. It needs to be explicitly created and configured with the necessary RBAC roles for the target resources.

To Create this type of service, this is the minimium permission required at the Resource Group or higher level:

| Resource | Required Role |
|----------|---------------|
| Key Vault | Key Vault Contributor  |
| Key Vault - Create Keys/Secrets/Certs | Key Vault administrator |
| Event Hub | Azure Event Hubs Data Owner |
| Azure Storage account | Storage Account Contributor |
| Azure Storage - Create Containers | Storage Blob Data Contributor |


