# Bash environment variables
rgName='test-spec-image2-rg'
vmName='vmspecimage'
imageRef='/subscriptions/xxxxx/resourceGroups/sig/providers/Microsoft.Compute/galleries/MySharedImageGallery/images/UbuntuWithTools'
location='eastus2'
vmSize='Standard_DS1_v2'

# PowerShell environment variables
# $rgName='test-spec-image-rg'
# $vmName='vmspecimage'
# $imageRef='/subscriptions/xxxxx/resourceGroups/sig/providers/Microsoft.Compute/galleries/MySharedImageGallery/images/UbuntuWithTools'
# $location='eastus2'
# $vmSize='Standard_DS1_v2'

# Create a resource group
az group create --name $rgName --location $location

# Create a VNET and Subnet
az network vnet create -g $rgName -n test-vnet --address-prefix "10.0.0.0/16"
az network vnet subnet create -g $rgName --vnet-name test-vnet -n test-subnet --address-prefix "10.0.0.0/24"

# Create a VM with a specialized image
   # If running in PowerShell
   # az vm create --resource-group $rgName --name $vmName --image $imageRef --location $location --size $vmSize --subnet test-subnet --vnet-name test-vnet --specialized --os-disk-delete-option=Delete --nic-delete-option=Delete  --public-ip-address '""' 

   # If running in Bash
   az vm create --resource-group $rgName --name $vmName --image $imageRef --location $location --size $vmSize --subnet test-subnet --vnet-name test-vnet --specialized --os-disk-delete-option=Delete --nic-delete-option=Delete  --public-ip-address '' --generate-ssh-keys

# Configure boot diagnostics
az vm boot-diagnostics enable --resource-group $rgName --name $vmName 