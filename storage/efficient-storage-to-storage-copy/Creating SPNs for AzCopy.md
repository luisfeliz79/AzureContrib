# Creating Service Principals for AzCopy

## Using a single SPN for both source and destination storage accounts
```bash

# Authenticate with a Global Administrator account to create the SPN and assign roles
az login


# Crete an Entra ID App registration with the cert , using Azure CLI
$SpnOne=az ad app create --display-name "SAcopySPN" --query appId -o tsv

# Create matching Enterprise Registration
az ad sp create --id $SpnOne

# Create a self-signed certificate to be used as the credential
openssl req -x509 -newkey rsa:4096 -sha256 -days 180 -nodes -keyout cred-private.key -out cred-public.pem -subj '/CN=sacopy-auth-openssl'
cat cred-private.key > private-and-public-combined.pem
cat cred-public.pem >> private-and-public-combined.pem

# Upload the public part of the certificate to the Entra ID App registration
az ad app credential reset --id $SpnOne --cert "@cred-public.pem" --append

# Configure RBAC role assignments for the SPN on both source and destination storage accounts

$saSourceId="/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<source-storage-account-name>"

$saDestId="/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<dest-storage-account-name>"


az role assignment create --assignee $SpnOne --role "Storage Blob Data Reader" --scope "$saSourceId"

az role assignment create --assignee $SpnOne --role "Storage Blob Data Contributor" --scope "$saDestId"
```

## Using Separate SPNs for source and destination storage accounts
```bash
# Authenticate with a Global Administrator account to create the SPN and assign roles
az login


# Crete an Entra ID App registration with the cert , using Azure CLI
$SpnSource=az ad app create --display-name "SAcopyTestAppSource" --query appId -o tsv

$SpnDest=az ad app create --display-name "SAcopyTestAppDest" --query appId -o tsv

# Create matching Enterprise Registration
az ad sp create --id $SpnSource
az ad sp create --id $SpnDest


# Create a self-signed certificate to be used as the credential (same cert can be used for both SPNs, but different certs can be used if desired)
openssl req -x509 -newkey rsa:4096 -sha256 -days 180 -nodes -keyout cred-private.key -out cred-public.pem -subj '/CN=sacopy-auth-openssl'
cat cred-private.key > private-and-public-combined.pem
cat cred-public.pem >> private-and-public-combined.pem

# Upload the public part of the certificate to the Entra ID App registration
az ad app credential reset --id $SpnSource --cert "@cred-public.pem" --append
az ad app credential reset --id $SpnDest --cert "@cred-public.pem" --append


# Configure RBAC role assignments for the source and destination storage accounts

$saSourceId="/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<source-storage-account-name>"

$saDestId="/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<dest-storage-account-name>"

az role assignment create --assignee $SpnSource --role "Storage Blob Data Reader" --scope "$saSourceId"

az role assignment create --assignee $SpnDest --role "Storage Blob Data Contributor" --scope "$saDestId"
```