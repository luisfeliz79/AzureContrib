
resource "azurerm_resource_group" "onpremgw" {
    name     = "MOLABS-onprem-gw"
    location = local.region
}

resource "azurerm_resource_group" "azuregw" {
    name     = "MOLABS-azure-gw"
    location = local.region
}

# resource "azurerm_resource_group" "azurenet1" {
#     name     = "MOLABS-azure-net1"
#     location = local.region
# }

resource "azurerm_resource_group" "azurefwhub" {
    name     = "MOLABS-azure-fwhub"
    location = local.region
}

resource "azurerm_resource_group" "azurespoke" {
    name     = "MOLABS-azure-spoke"
    location = local.region
}

module "read_password" {
    source = "../modules/get-secure-string"
    file_path = "c:\\users\\lufeliz\\autoinfo.sec"
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length = 5
  upper = false
  special = false
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "include_route_server" {
  value = local.include_route_server
}
output "include_vnetgw" {
  value = local.include_vnetgw
}
output "include_firewall" {
  value = local.include_firewall
}
