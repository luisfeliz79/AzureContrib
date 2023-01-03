# OnPrem Simulated VNET 
resource "azurerm_virtual_network" "onprem_vnet" {
    name                        = "RSLAB-vnetOnPrem"
    location                    = var.location 
    resource_group_name         = azurerm_resource_group.onprem_rg.name
    address_space               = ["10.20.0.0/16"]
}


# The OnPremRouter Subnet
resource "azurerm_subnet" "OnPrem_Router" {
  name                      = "OnPremRouter"
  resource_group_name       = azurerm_resource_group.onprem_rg.name
  virtual_network_name      = azurerm_virtual_network.onprem_vnet.name
  address_prefixes          = ["10.20.0.0/24"]
}





# Create needed NSGs

resource "azurerm_network_security_group" "onprem_router_nsg" { 
    name                        = "OnPremRouter_nsg"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.onprem_rg.name

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

resource "azurerm_subnet_network_security_group_association" "onprem_router_nsg_assoc" {
  subnet_id                 = azurerm_subnet.OnPrem_Router.id
  network_security_group_id = azurerm_network_security_group.onprem_router_nsg.id  
}

