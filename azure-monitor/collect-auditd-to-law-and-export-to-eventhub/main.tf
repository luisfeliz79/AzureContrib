locals {
    prefix         = "auditd"            # identifier added to all resources
    region0        = "eastus2"           # Region where resouces will be deployed
    admin_username = "azureadmin"        # Admin username for the VM
    vm_size        = "Standard_D2ads_v5" # Size of the VM
}

# Get the current Azure client configuration
data "azurerm_client_config" "current" {}

# Create a resource group
resource "azurerm_resource_group" "rg0" {
    name = "rg-${local.prefix}-${local.region0}"
    location = local.region0
}
