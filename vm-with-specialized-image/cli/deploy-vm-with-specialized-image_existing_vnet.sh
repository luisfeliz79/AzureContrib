# Bash environment variables
rgName='test-spec-image2-rg'
vmName='vmspecimage'
imageRef='/subscriptions/xxxxx/resourceGroups/sig/providers/Microsoft.Compute/galleries/MySharedImageGallery/images/UbuntuWithTools'
location='eastus2'
vmSize='Standard_DS1_v2'
existingSubnetId='/subscriptions/xxxxx/resourceGroups/test-spec-image2-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet'

# PowerShell environment variables
# $rgName='test-spec-image-rg'
# $vmName='vmspecimage'
# $imageRef='/subscriptions/xxxxx/resourceGroups/sig/providers/Microsoft.Compute/galleries/MySharedImageGallery/images/UbuntuWithTools'
# $location='eastus2'
# $vmSize='Standard_DS1_v2'
# $existingSubnetId='/subscriptions/xxxxx/resourceGroups/test-spec-image-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet'



# Create a resource group
az group create --name $rgName --location $location

# Create a VM with a specialized image
   # If running in PowerShell
   # az vm create --resource-group $rgName --name $vmName --image $imageRef --location $location --size $vmSize --subnet $existingSubnetId  --specialized  --os-disk-delete-option=Delete --nic-delete-option=Delete  --public-ip-address '""' 

   # If running in Bash
   az vm create --resource-group $rgName --name $vmName --image $imageRef --location $location --size $vmSize --subnet $existingSubnetId  --specialized  --os-disk-delete-option=Delete --nic-delete-option=Delete  --public-ip-address '' --generate-ssh-keys


# Configure boot diagnostics
az vm boot-diagnostics enable --resource-group $rgName --name $vmName 