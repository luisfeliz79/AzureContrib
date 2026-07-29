
# Existing resources
$subscription="<subscription>"
$RG="<rg>"
$SubnetResourceId="<resourceId>"

# VM Details
$Location="eastus2"
$VM_NAME="cisco-nva-1"
$SKU="Standard_D4s_v5"
$ImagePublisher="cisco"
$ImageOffer="cisco-c8000v-byol"
$ImageSku="17_18_02-byol"
$ImageVersion="latest" 
$adminusername="<user>"
$adminpassword="<pass>"

$Image="$($ImagePublisher):$($ImageOffer):$($ImageSku):$($ImageVersion)"

az account set --subscription $subscription

# Accept the legal terms for the image
az vm image terms accept --publisher $ImagePublisher --offer $ImageOffer --plan $ImageSku

# Create a VM using Azure CLI
az vm create `
  --resource-group $RG `
  --name $VM_NAME `
  --image $Image `
  --size $SKU `
  --subnet $SubnetResourceId `
  --generate-ssh-keys `
  --accept-term `
  --location $Location `
  --admin-username $adminusername `
  --admin-password $adminpassword `
  --authentication-type password `
  --accelerated-networking `
  --nic-delete-option   Delete `
  --os-disk-delete-option Delete `
  --public-ip-address '""' `
  --storage-sku StandardSSD_LRS `
  --subnet $SubnetResourceId

az vm boot-diagnostics enable --name $VM_NAME `
   --resource-group $RG 


