# Get info about the existing VHUB
data "azurerm_virtual_hub" "existing-vhub" {
  provider = azurerm.vwan-subscription

  name                = var.vhub_name
  resource_group_name = var.vhub_rg
}

# Link the Spoke to the VHUB
resource "azurerm_virtual_hub_connection" "hubconnection" {

  provider = azurerm.vwan-subscription

  name                      = "connection-to-hub"
  virtual_hub_id            = data.azurerm_virtual_hub.existing-vhub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id
  internet_security_enabled = true

}