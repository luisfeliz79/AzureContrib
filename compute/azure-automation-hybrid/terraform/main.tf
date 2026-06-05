

# # Resource Group Create
# resource "azurerm_resource_group" "rg" {
#   name     = local.resource_group_name
#   location = local.location
# }

# Pre-created Resource Group read
data "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
}

locals {
  resource_group_id = data.azurerm_resource_group.rg.id
}

# client config
data "azurerm_client_config" "current" {}


