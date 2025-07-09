resource "azurerm_virtual_network" "azurespoke" {
    name                        = "vnet-azurespoke"
    location                    = local.region
    resource_group_name         = azurerm_resource_group.azurespoke.name
    address_space               = [local.azurespoke_vnet_cidr]

    tags = local.tags

  lifecycle {
    ignore_changes = all 
  }
}

# Create a subnet
resource "azurerm_subnet" "azurespoke-default" {
  name                      = "default"
  resource_group_name       = azurerm_resource_group.azurespoke.name
  virtual_network_name      = azurerm_virtual_network.azurespoke.name
  address_prefixes          = [local.azurespoke_subnet_default_cidr]

  #private_endpoint_network_policies = "Enabled"
}

# Create a subnet
resource "azurerm_subnet" "azurespoke-endpoint" {
  name                      = "endpoints"
  resource_group_name       = azurerm_resource_group.azurespoke.name
  virtual_network_name      = azurerm_virtual_network.azurespoke.name
  address_prefixes          = [local.azurespoke_subnet_endpoints_cidr]

  #private_endpoint_network_policies = "Enabled"
}


# Associate the NSG
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_spoke_1" {
  subnet_id                 = azurerm_subnet.azurespoke-default.id
  network_security_group_id = azurerm_network_security_group.nsg-default.id
}

# Associate the NSG
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_spoke_2" {
  subnet_id                 = azurerm_subnet.azurespoke-endpoint.id
  network_security_group_id = azurerm_network_security_group.nsg-default.id
}


