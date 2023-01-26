# Spoke VNET 
resource "azurerm_virtual_network" "spoke_vnet" {
    name                        = "RSLAB-vnetSpoke"
    location                    = var.location 
    resource_group_name         = azurerm_resource_group.spoke_rg.name
    address_space               = ["10.230.0.0/16"]
}


# The TestClients Subnet
resource "azurerm_subnet" "spoke_TestClients" {
  name                      = "TestClients"
  resource_group_name       = azurerm_resource_group.spoke_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  address_prefixes          = ["10.230.0.0/24"]
}

# The Apps Subnet
resource "azurerm_subnet" "spoke_Apps" {
  name                      = "Apps"
  resource_group_name       = azurerm_resource_group.spoke_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  address_prefixes          = ["10.230.1.0/24"]


}

# The Functions Subnet
resource "azurerm_subnet" "spoke_Functions" {
  name                      = "Functions"
  resource_group_name       = azurerm_resource_group.spoke_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  address_prefixes          = ["10.230.2.0/24"]

    delegation {
    name = "webapps-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
  
}



