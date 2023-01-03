# Hub VNET 
resource "azurerm_virtual_network" "hub_vnet" {
    name                        = "RSLAB-vnetHub"
    location                    = var.location 
    resource_group_name         = azurerm_resource_group.hub_rg.name
    address_space               = ["10.50.0.0/16"]
}


# The internal Subnet
resource "azurerm_subnet" "hub_internal" {
  name                      = "NVA_Internal"
  resource_group_name       = azurerm_resource_group.hub_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  address_prefixes          = ["10.50.1.0/24"]
}

# The external Subnet
resource "azurerm_subnet" "hub_external" {
  name                      = "NVA_External"
  resource_group_name       = azurerm_resource_group.hub_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  address_prefixes          = ["10.50.2.0/24"]
}

# The support Subnet
resource "azurerm_subnet" "hub_support" {
  name                      = "Support"
  resource_group_name       = azurerm_resource_group.hub_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  address_prefixes          = ["10.50.3.0/24"]
}

# The support Subnet
resource "azurerm_subnet" "hub_RouteServer" {
  name                      = "RouteServerSubnet"
  resource_group_name       = azurerm_resource_group.hub_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  address_prefixes          = ["10.50.254.0/24"]
  # TODO: change this to a 27
}




# Create needed NSGs

resource "azurerm_network_security_group" "hub_mgmt_nsg" { 
    name                        = "NVA_mgmt_nsg"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.hub_rg.name

    security_rule {      
      name                        = "AllowRDP22390"
      priority                    = 100
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Tcp"
      source_port_range           = "*"
      destination_port_range      = "22389"
      source_address_prefix       = "Internet"
      destination_address_prefix  = "*"
    }
   
}

resource "azurerm_network_security_group" "hub_external_nsg" { 
    name                        = "NVA_external_nsg"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.hub_rg.name

    security_rule {      
      name                        = "AllowUDP500"
      priority                    = 100
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Udp"
      source_port_range           = "*"
      destination_port_range      = "500"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
    }

    security_rule {      
      name                        = "AllowUDP4500"
      priority                    = 101
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Udp"
      source_port_range           = "*"
      destination_port_range      = "4500"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
    }

    security_rule {      
      name                        = "AllowRDP22389"
      priority                    = 102
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Tcp"
      source_port_range           = "*"
      destination_port_range      = "22389"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
    }
   
   
}

# Associate the NSGs
resource "azurerm_subnet_network_security_group_association" "external_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_external.id
  network_security_group_id = azurerm_network_security_group.hub_external_nsg.id
}


# # For NAT Configuration
# resource "azurerm_route_table" "WANRoute" {
#   name                          = "hub-routetable-wan"
#   location                    = var.location
#   resource_group_name         = azurerm_resource_group.hub_rg.name
#   disable_bgp_route_propagation = true

#   route {
#     name           = "Default_to_Internet"
#     address_prefix = "0.0.0.0/0"
#     next_hop_type  = "Internet"
#   }

# }

# resource "azurerm_subnet_route_table_association" "WANRouteAssoc" {
#   subnet_id      = azurerm_subnet.hub_external.id  
#   route_table_id = azurerm_route_table.WANRoute.id
# }