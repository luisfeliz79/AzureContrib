# VNET 
resource "azurerm_virtual_network" "vnet" {
    name                        = "${local.rg_prefix}-vnet"
    location                    = azurerm_resource_group.rg.location 
    resource_group_name         = azurerm_resource_group.rg.name
    address_space               = [local.vnet_prefix  ]
    tags = local.tags
}

# functions subnet
resource "azurerm_subnet" "functions_subnet" {
  name                      = "functions"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = [local.functions_subnet]

  delegation {
    name = "appservice-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# endpoints
resource "azurerm_subnet" "endpoints_subnet" {
  name                      = "endpoints"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = [local.endpoints_subnet]
}


# Default Route Table
resource "azurerm_route_table" "default_route" {
  name                        = "${local.rg_prefix}-default-route-table"
  location                    = azurerm_resource_group.rg.location 
  resource_group_name         = azurerm_resource_group.rg.name
  
  # route {
  #   name           = "RouteAll"
  #   address_prefix = "0.0.0.0/0"
  #   next_hop_type  = "VirtualAppliance"
  #   next_hop_in_ip_address = "x.x.x.x"
  # }

  tags = local.tags

}

resource "azurerm_subnet_route_table_association" "functions_default_route_assoc" {
  subnet_id      = azurerm_subnet.functions_subnet.id
  route_table_id = azurerm_route_table.default_route.id
}

resource "azurerm_subnet_route_table_association" "endpoints_default_route_assoc" {
  subnet_id      = azurerm_subnet.endpoints_subnet.id
  route_table_id = azurerm_route_table.default_route.id
}
