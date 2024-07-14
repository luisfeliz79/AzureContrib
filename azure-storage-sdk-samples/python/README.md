# Azure Storage SDK for Python - Blob Storage - Sample

## Pre-requisites
    1. Create a storage account (Standard or Premium) in Azure
    2. Create a container in the storage account
    3. Configure RBAC permissions as specified in the [Azure Storage RBAC documentation](https://docs.microsoft.com/en-us/azure/storage/common/storage-auth-aad-rbac-portal)


## Configure the sample
- Update these two lines in app.py with the storage account and container information
```python
    # Specify the storage account name and container name 
    accountName = "<the storage account name (not the fqdn)>"
    container = "<the name of a container>"
```

## Authentication using [DefaultAzureCredential](https://learn.microsoft.com/en-us/python/api/azure-identity/azure.identity.defaultazurecredential?view=azure-python)

### If using Service Principal

- If you have previously used az login, ensure to log out first, using az logout
- Configure the environment variables

```bash
# For Bash / Linux
export AZURE_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export AZURE_TENANT_ID="xxxxx.onmicrosoft.com or 00000000-0000-0000-0000-000000000000"
export AZURE_CLIENT_CERTIFICATE_PATH="/path/to/certificate.pem"

# For PowerShell / Windows (or Linux)
$env:AZURE_CLIENT_ID="00000000-0000-0000-0000-000000000000"
$env:AZURE_TENANT_ID="xxxxx.onmicrosoft.com or 00000000-0000-0000-0000-000000000000"
$env:AZURE_CLIENT_CERTIFICATE_PATH="C:\Azure\sp-cert.pem"
```
Make sure to add permisions such as "Storage Blob Data Contributor" to the Service principal
- Then run the sample



### If using Managed Identity (System Assigned)
- Enable the system assigned managed identity in the Azure service
- Make sure to add permisions such as "Storage Blob Data Contributor" to the managed identity
- Then run the sample



### If using Managed Identity (User Assigned)

- Uncomment and Update this line in the sample to include the UA Managed Identity APPID

```python        
        client_id = "<your client id>"
        default_credential = DefaultAzureCredential(managed_identity_client_id=client_id)
        # It is also possible to just set environment variable: AZURE_CLIENT_ID
```

- Comment out the existing DefaultAzureCredential line
```python
        #default_credential = DefaultAzureCredential()
```
- Make sure to add permisions such as "Storage Blob Data Contributor" to the managed identity
- Then run the sample

### For authenticating with the Logged in user
- Login interactively as the user using the Azure CLI

```bash
az login
```
- Make sure to add permisions such as "Storage Blob Data Contributor" to the managed identity
- Then run the sample

## Running the sample

- Linux/Bash

```bash
# Create a virtual environment and activate it
cd python
python -m venv blob
source blob/bin/activate

# Install the required libraries
pip install azure-storage-blob azure-identity

# Run the sample
python app.py
```

- Windows/PowerShell

```powershell
# Create a virtual environment and activate it
cd python
python -m venv blob
.\blob\scripts\activate.ps1

# Install the required libraries
pip install azure-storage-blob azure-identity

# Run the sample
python app.py
```
