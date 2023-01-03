# Hub-Spoke Peering
resource "azurerm_virtual_network_peering" "hub_spoke_peering" {
    name                        = "hub_spoke_peer"
    resource_group_name         = azurerm_resource_group.hub_rg.name
    virtual_network_name        = azurerm_virtual_network.hub_vnet.name
    remote_virtual_network_id   = azurerm_virtual_network.spoke_vnet.id
    allow_forwarded_traffic     = true
    allow_gateway_transit       = true 



    depends_on = [
      azurerm_route_server.rs1
    ]
   
}



# Spoke-Hub Peering
resource "azurerm_virtual_network_peering" "spoke_hub_peering" {
    name                        = "spoke_hub_peer"
    resource_group_name         = azurerm_resource_group.spoke_rg.name
    virtual_network_name        = azurerm_virtual_network.spoke_vnet.name 
    remote_virtual_network_id   = azurerm_virtual_network.hub_vnet.id
    allow_forwarded_traffic     = true
    use_remote_gateways         = true

    depends_on = [
      azurerm_virtual_network_peering.hub_spoke_peering
    ]

}



