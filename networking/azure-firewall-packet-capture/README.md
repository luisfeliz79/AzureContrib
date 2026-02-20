# Azure Firewall Packet Capture

This is a guide to demonstrate how to use Azure Firewall's Packet Capture feature via Azure CLI. The packet capture feature allows you to capture network traffic that is processed by the Azure Firewall, which can be useful for troubleshooting and analyzing network issues.

## Pre-requisites
- Azure Firewall with Management Public IP enabled
- Storage account and a Container.  The Storage account firewall should be configured to allow access from Trusted Services and from the runner machine Egress IP
	
- An Identity such as a User Account, Service Principal or Managed Identity

- RBAC permissions for the Identity:
	- Storage Blob Data Contributor  for the Storage account
	- Network Contributor for the Azure Firewall
## Authentication and Authorization

```
# Different ways to authenticate Azure CLI

# Interactive
az login 
	--or--
az login --use-device-code

# Using Managed Identity
az login --identity

# Using Service Principal
SPN="<client-id>"
tenantId="<tenant-id-or-name>"
az login --service-principal --username $SPN --certificate /home/user/certificate-combined.pem  --tenant $tenantId

```

## Obtaining a SAS URL for the Storage Account Container
This will be used with the Azure CLI to write the completed packet capture files.

You also can optionally use the generated SAS URL to run the packet capture from the Azure Portal

```
# Get SAS URL
storageAccount=luissourcesa
container=packetcapture

expire_date=$(date --utc -d "+1 hours" +'%Y-%m-%dT%H:%MZ')
permissions_write='rwl' #(r)ead (w)rite (l)ist

echo "Requesting SAS URL with expiration of UTC ${expire_date}"

storage_account_sas=$(az storage container generate-sas --permissions $permissions_write --name $container --account-name $storageAccount --expiry $expire_date -o tsv --auth-mode login --as-user)

storage_account_sas_url="https://luissourcesa.blob.core.windows.net/packetcapture?$storage_account_sas"

echo ""
echo "$storage_account_sas_url"

```

## Peforming Packet Capture Operations via Azure CLI

### Install Azure CLI and the needed extension
- To install the Azure CLI, use the guide here:
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt

- To install the Azure Firewall extension, use the command:
    ```
    az extension add --name azure-firewall
    ```
### Run the Packet Capture
```
# Step 1 - Define Azure Firewall details
fw_name="<firewall-name>"
fw_resourcegroup="<firewall-rg>"

# Step 2 - Define Packet capture details
filters="[{sources:[10.17.0.4],destinations:[104.26.7.112,104.26.6.112,172.67.68.101],destination-ports:[443]}]"

# Step 3 - This will compute a filename, leave as is or change as desired.  Note: do not add an extension, the system will add .pcap when writing the file to storage
filename_date=$(date --utc +'%Y-%m-%dT%H-%MZ')
filename="packetcapture-$filename_date"

# Step 4 - Kick off the capture
# Ensure the $storage_account_sas_url has been already set
echo "Starting a capture to file ${filename}"

az network firewall packet-capture-operation \
          --resource-group $fw_resourcegroup \
          --azure-firewall-name $fw_name \
          --operation Start \
          --duration-in-seconds 1800 \
          --number-of-packets-to-capture 5000 \
          --sas-url $storage_account_sas_url \
          --file-name $filename \
          --protocol Any \
          --flags "[{type:syn},{type:fin}]" \
          --filters $filters
```

### Optional Steps

- Get Status if desired
    ```
    az network firewall packet-capture-operation \
            --resource-group $fw_resourcegroup \
            --azure-firewall-name $fw_name \
            --operation Status
    ```
- Stop the packet capture early
    ```
    az network firewall packet-capture-operation \
            --resource-group $fw_resourcegroup \
            --azure-firewall-name $fw_name \
            --operation Stop
    ```
