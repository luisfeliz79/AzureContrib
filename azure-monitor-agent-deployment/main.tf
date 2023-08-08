locals {
    prefix         = "amatest"          # identifier added to all resources
    region0        = "eastus2"          # Region where resouces will be deployed
    admin_username = "azureadmin"       # Admin username for the VM
    vm_size        = "Standard_D2as_v4" # Size of the VM    
}

# Create a resource group
resource "azurerm_resource_group" "rg0" {
    name = "rg-${local.prefix}-${local.region0}"
    location = local.region0
}
