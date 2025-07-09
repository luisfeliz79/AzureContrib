resource "azurerm_virtual_network" "azuregw" {
    name                        = "vnet-azuregw"
    location                    = local.region
    resource_group_name         = azurerm_resource_group.azuregw.name
    address_space               = [local.azuregw_vnet_cidr]

    tags = local.tags

  lifecycle {
    ignore_changes = all 
  }
}

# Create a subnet
resource "azurerm_subnet" "azuregw-nva" {
  name                      = "nva"
  resource_group_name       = azurerm_resource_group.azuregw.name
  virtual_network_name      = azurerm_virtual_network.azuregw.name
  address_prefixes          = [local.azuregw_subnet_nva_cidr]

  #private_endpoint_network_policies = "Enabled"
}

# Create a subnet
resource "azurerm_subnet" "azuregw-rs" {
  name                      = "RouteServerSubnet"
  resource_group_name       = azurerm_resource_group.azuregw.name
  virtual_network_name      = azurerm_virtual_network.azuregw.name
  address_prefixes          = [local.azuregw_subnet_routeserver_cidr]

  #private_endpoint_network_policies = "Enabled"
}

# Create a subnet
resource "azurerm_subnet" "azuregw-gw" {
  name                      = "GatewaySubnet"
  resource_group_name       = azurerm_resource_group.azuregw.name
  virtual_network_name      = azurerm_virtual_network.azuregw.name
  address_prefixes          = [local.azuregw_subnet_vnetgw_cidr]

  #private_endpoint_network_policies = "Enabled"
}

# Create a subnet
resource "azurerm_subnet" "azuregw-appsvc" {
  name                      = "app-service"
  resource_group_name       = azurerm_resource_group.azuregw.name
  virtual_network_name      = azurerm_virtual_network.azuregw.name
  address_prefixes          = [local.azuregw_subnet_appsvc_cidr]

  # Azure App Service delegation
  delegation {
    name = "appsvc-delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }


  #private_endpoint_network_policies = "Enabled"
}

# Create a subnet
resource "azurerm_subnet" "azuregw-endpoints" {
  name                      = "endpoints"
  resource_group_name       = azurerm_resource_group.azuregw.name
  virtual_network_name      = azurerm_virtual_network.azuregw.name
  address_prefixes          = [local.azuregw_subnet_endpoints_cidr]

  #private_endpoint_network_policies = "Enabled"
}



# Associate the NSG
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_azuregw_1" {
  subnet_id                 = azurerm_subnet.azuregw-nva.id
  network_security_group_id = azurerm_network_security_group.nsg-default.id
}




