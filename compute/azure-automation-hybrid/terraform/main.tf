

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}

# client config
data "azurerm_client_config" "current" {}


