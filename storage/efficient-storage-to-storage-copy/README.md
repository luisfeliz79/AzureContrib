# Using AZCOPY for efficient Storage-to-Storage Copy

This guide provides instructions on how to use AZCOPY, a command-line tool designed for fast and efficient data transfer between Azure Storage accounts.

AZCOPY is particularly useful for copying large amounts of data, as it optimizes the transfer process by having the destination storage account pull the data directly from the source storage account, eliminating the need for data to pass through an intermediary system.

# Table of contents
- [Prerequisites](#prerequisites)
- [Example AZCOPY commands](#example-azcopy-commands)
- [Authentication](#authentication)
- [Configuration considerations](#configuration-considerations)
- [AZCOPY Scenarios examples](#azcopy-scenarios-examples)
  - [Scenario 1: Using AzCopy from an Azure VM or PaaS service using Managed Identity](#scenario-1-using-azcopy-from-an-azure-vm-or-paas-service-using-managed-identity)
  - [Scenario 2: Using AzCopy from an on-premises environment using Service Principal + Certificate credential](#scenario-2-using-azcopy-from-an-on-premises-environment-using-service-principal--certificate-credential)
  - [Scenario 3: Using AzCopy with two separate identities for the source and destination (example Prod and Dev require separate identities)](#scenario-3-using-azcopy-with-two-separate-identities-for-the-source-and-destination-example-prod-and-dev-require-separate-identities)

<br>

## Prerequisites

Before you begin, ensure you have the following:

- The AZCOPY utility. You can download it from the [official Azure website](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10).

- The Azure CLI utility (for some scenarios). You can download it from the [official Azure website](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

- RBAC access to both the source and destination Azure Storage accounts.
    - For the source storage account, you need at least the "Storage Blob Data Reader" role.
    - For the destination storage account, you need at least the "Storage Blob Data Contributor" role.

- Network access to both storage accounts from the environment where you will run AZCOPY.
    - Using the public endpoint and ensuring that your IP address is allowed in the storage account's firewall settings.
    -- or --
    - Using Private Endpoints if your storage accounts are configured to use them.

## Example AZCOPY commands:
```bash

# General syntax of source and destination URLs
sourceUrl="https://$sourceAccount.blob.core.windows.net/$sourceContainer/"
destUrl="https://$destinationAccount.blob.core.windows.net/$destinationContainer"

# Copy all files from one storage account container to another
azcopy copy --recursive $sourceUrl $destUrl

# Copy only new files from one storage account container to another
azcopy copy --recursive $sourceUrl $destUrl --overwrite false

# Copy only new and modified files from one storage account container to another
# To do this, the --include-after flag is used to specify a date and time.
# Only files modified after this date and time will be copied.
azcopy copy --recursive $sourceUrl $destUrl --overwrite ifSourceNewer
```

<br>

## Authentication
Before the AZCOPY utility can be used, it must be authenticated to access the Azure Storage accounts. 
AZCOPY supports multiple authentication methods to accommodate different scenarios:



| Authentication Method | Description             | Use Case                |
|--------------------|-------------------------|-------------------------|
| Managed Identity         | When AzCopy is running on an Azure VM or PaaS Service. | Ideal for services that support managed identity, for example Virtual machines or Azure Automation accounts. |
| Service Principal + Certificate credential | Uses a service principal with a certificate for authentication. | Suitable for scenarios the AzCopy utility is running from an on-premises environment or outside of Azure Cloud |
| EntraID backed SAS URL        | SAS Urls are created from EntraID Principals | Suitable for scenarios need separate identities for the source and destination accounts. 

**Notes**: 
- To see examples of how to create the SPNs and certificate credentials, [see here](./Creating%20SPNs%20for%20AzCopy.md)
- There are other, less secure authentication methods available that are not recommended for production use and will not be covered here.

<br>

## Configuration considerations

The security feature ["Permitted scope for copy operations (preview)"](https://learn.microsoft.com/en-us/azure/storage/common/security-restrict-copy-operations?tabs=portal) could further restrict the copy operations based on the selected settings. Check the destination storage account's configuration under Settings > Configuration > Permitted scope for copy operations.

Setting | Restriction
--- | ---
From any storage account | No restrictions
From storage accounts in the same Azure AD tenant | If using separate identities for the source and destination storage accounts, the identities must be from the same tenant.
From storage accounts that have a private endpoint to the same virtual network | AZCOPY needs to access both accounts via Private endpoints.

<br><br>

# AZCOPY Scenarios examples

## Scenario 1: Using AzCopy from an Azure VM or PaaS service using Managed Identity
```bash
sourceAccount="<name-of-source-storage-account>"
sourceContainer="<source-container>"
destinationAccount="<name-of-destination-storage-account>"
destinationContainer="<dest-container>"

# Construct the source and destination URLs
sourceUrl="https://$sourceAccount.blob.core.windows.net/$sourceContainer/"
destUrl="https://$destinationAccount.blob.core.windows.net/$destinationContainer"

# If using a System assigned managed identity, login can be done this way:
azcopy login --identity

# If using a User assigned managed identity, the identity can be specified this way:
# azcopy login --identity --identity-object-id "[ServiceIdentityObjectID]"
# or
# azcopy login --identity --identity-resource-id "/subscriptions/<subscriptionId>/resourcegroups/myRG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myID"

# Perform the copy operation
azcopy copy --recursive $sourceUrl $destUrl --overwrite ifSourceNewer
```

### Scenario 2: Using AzCopy from an on-premises environment using Service Principal + Certificate credential
```bash
sourceAccount="<name-of-source-storage-account>"
sourceContainer="<source-container>"
destinationAccount="<name-of-destination-storage-account>"
destinationContainer="<dest-container>"

tenantId="<tenant-id>"
spnOne="<service-principal-client-id>"

# Construct the source and destination URLs
sourceUrl="https://$sourceAccount.blob.core.windows.net/$sourceContainer/"
destUrl="https://$destinationAccount.blob.core.windows.net/$destinationContainer"

# In this case, it is recommended to use the Azure CLI to authenticate first and leverage its token cache.  Azure CLI has much better support for certificate-based authentication than AzCopy.

# Note: --certificate must point to an absolute path
az login --service-principal --username $spnOne --certificate /home/user/private-and-public-combined.pem  --tenant $tenantId

# Set environment variables to use Azure CLI for authentication in AzCopy
export AZCOPY_AUTO_LOGIN_TYPE=AZCLI
export AZCOPY_TENANT_ID=$tenantId

# Perform the copy operation
azcopy copy --recursive $sourceUrl $destUrl --overwrite ifSourceNewer
```

### Scenario 3: Using AzCopy with two separate identities for the source and destination (example Prod and Dev require separate identities)
```bash
sourceAccount="<name-of-source-storage-account>"
sourceContainer="<source-container>"
destinationAccount="<name-of-destination-storage-account>"
destinationContainer="<dest-container>"

tenantId="<tenant-id>"
SpnSource="<service-principal-client-id>"
SpnDest="<service-principal-client-id>"


# Generate Entra ID backed SAS tokens for both source and destination storage accounts using Azure CLI
expire_date=$(date -d "+72 hours" +'%Y-%m-%dT%H:%MZ')
permissions_read='rl' #(c)reate (r)ead (a)ppend (w)rite (l)ist
permissions_write='rwl' #(c)reate (r)ead (a)ppend (w)rite (l)ist

# Login with source identity and generate read-only SAS for source container
az login --service-principal --username $SpnSource --certificate /home/user/private-and-public-combined.pem  --tenant $tenantId

source_readonly_sas=$(az storage container generate-sas --permissions $permissions_read --name $sourceContainer  --account-name $sourceAccount --expiry $expire_date -o tsv --auth-mode login --as-user)

# Login with destination identity and generate write SAS for destination container
az login --service-principal --username $SpnDest --certificate /home/user/private-and-public-combined.pem  --tenant $tenantId

destination_write_sas=$(az storage container generate-sas --permissions $permissions_write --name $destinationContainer  --account-name $destinationAccount --expiry $expire_date -o tsv --auth-mode login --as-user)

# Construct the source and destination URLs with SAS tokens
sourceUrl="https://$sourceAccount.blob.core.windows.net/$sourceContainer?$source_readonly_sas"
destUrl="https://$destinationAccount.blob.core.windows.net/$destinationContainer/?$destination_write_sas"

# Perform the copy operation
azcopy copy --recursive $sourceUrl $destUrl --overwrite false
```
