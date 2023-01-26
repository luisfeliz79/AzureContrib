# Spoke VNET 
resource "azurerm_virtual_network" "spoke_vnet" {
    name                        = "vnet-${local.cluster_name}"
    location                    = local.location 
    resource_group_name         = azurerm_resource_group.rg.name
    address_space               = local.address_space
}


# The akscni Subnet
resource "azurerm_subnet" "spoke_akscni" {
  name                      = "snet-akscni"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  address_prefixes          = local.subnet_akscni_space

  service_endpoints = [ "Microsoft.Storage" ]

}




