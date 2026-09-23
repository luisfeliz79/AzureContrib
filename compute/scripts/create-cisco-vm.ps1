Param
(
  [Parameter (Mandatory=$false)]   [String] $subscription = "",
  [Parameter (Mandatory=$false)]   [String] $RG = "",
  [Parameter (Mandatory=$false)]   [String] $SubnetResourceId = "",
  [Parameter (Mandatory=$false)]   [String] $Location = "eastus",
  [Parameter (Mandatory=$false)]   [String] $VM_NAME="cisco-nva-1",
  [Parameter (Mandatory=$false)]   [String] $SKU="Standard_D4s_v5",
  [Parameter (Mandatory=$false)]   [String] $ImagePublisher="cisco",
  [Parameter (Mandatory=$false)]   [String] $ImageOffer="cisco-c8000v-byol",
  [Parameter (Mandatory=$false)]   [String] $ImageSku="17_18_02-byol",
  [Parameter (Mandatory=$false)]   [String] $ImageVersion="latest",
  [Parameter (Mandatory=$false)]   [String] $adminusername="<user>"
)



# Automatic Variables
$adminpassword=Get-AutomationVariable -Name 'VM_PASS'
$Image="$($ImagePublisher):$($ImageOffer):$($ImageSku):$($ImageVersion)"

az login --identity

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




# Set the auto-shutdown and auto-start properties for the VM
$SHUTDOWN_TIME="18:00"  #in UTC
az vm auto-shutdown -g $RG -n $VM_NAME --time $SHUTDOWN_TIME 

