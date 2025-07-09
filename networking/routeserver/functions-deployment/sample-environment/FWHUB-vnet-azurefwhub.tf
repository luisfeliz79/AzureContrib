resource "azurerm_virtual_network" "azurefwhub" {
    name                        = "vnet-azurefwhub"
    location                    = local.region
    resource_group_name         = azurerm_resource_group.azurefwhub.name
    address_space               = [local.azurefwhub_vnet_cidr]

    tags = local.tags

  lifecycle {
    ignore_changes = all 
  }
}


# Create a subnet
resource "azurerm_subnet" "azurefwhub-fw" {
  name                      = "AzureFirewallSubnet"
  resource_group_name       = azurerm_resource_group.azurefwhub.name
  virtual_network_name      = azurerm_virtual_network.azurefwhub.name
  address_prefixes          = [local.azurefwhub_subnet_firewall_cidr]

  #private_endpoint_network_policies = "Enabled"
}


# Create a subnet
resource "azurerm_subnet" "azurefwhub-fw-mgmt" {
  name                      = "AzureFirewallManagementSubnet"
  resource_group_name       = azurerm_resource_group.azurefwhub.name
  virtual_network_name      = azurerm_virtual_network.azurefwhub.name
  address_prefixes          = [local.azurefwhub_subnet_firewallmgmt_cidr]

  #private_endpoint_network_policies = "Enabled"
}


# Create a subnet
resource "azurerm_subnet" "azurefwhub-client" {
  name                      = "client"
  resource_group_name       = azurerm_resource_group.azurefwhub.name
  virtual_network_name      = azurerm_virtual_network.azurefwhub.name
  address_prefixes          = [local.azurefwhub_subnet_client_cidr]

  #private_endpoint_network_policies = "Enabled"
}



