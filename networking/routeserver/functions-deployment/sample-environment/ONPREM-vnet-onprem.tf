resource "azurerm_virtual_network" "onprem" {
    name                        = "vnet-onprem"
    location                    = local.region
    resource_group_name         = azurerm_resource_group.onpremgw.name
    address_space               = [local.onprem_vnet_cidr]

    tags = local.tags

  lifecycle {
    ignore_changes = all 
  }
}

# Create a subnet
resource "azurerm_subnet" "onprem-nva" {
  name                      = "nva"
  resource_group_name       = azurerm_resource_group.onpremgw.name
  virtual_network_name      = azurerm_virtual_network.onprem.name
  address_prefixes          = [local.onprem_subnet_nva_cidr]

  #private_endpoint_network_policies = "Enabled"
}

# Create a subnet
resource "azurerm_subnet" "onprem-client" {
  name                      = "clients"
  resource_group_name       = azurerm_resource_group.onpremgw.name
  virtual_network_name      = azurerm_virtual_network.onprem.name
  address_prefixes          = [local.onprem_subnet_client_cidr]

  #private_endpoint_network_policies = "Enabled"
}

# Associate the NSG
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_onprem_1" {
  subnet_id                 = azurerm_subnet.onprem-nva.id
  network_security_group_id = azurerm_network_security_group.nva-external.id
}

# Associate the NSG
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_onprem_2" {
  subnet_id                 = azurerm_subnet.onprem-client.id
  network_security_group_id = azurerm_network_security_group.nsg-default.id
}



