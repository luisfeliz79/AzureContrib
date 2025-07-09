# # Create needed Route tables
# resource "azurerm_route_table" "spokes-to-fw" {
#   name                        = "spokes-to-fw-rt"
#   location                    = azurerm_virtual_network.azurefwhub.location
#   resource_group_name         = azurerm_virtual_network.azurefwhub.resource_group_name
#   #disable_bgp_route_propagation = true

#   route {
#     name           = "route-to-fw"
#     address_prefix = "0.0.0.0/0"
#     next_hop_type  = "VirtualAppliance"
#     # next_hop_type - Options: VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance and None.
#     next_hop_in_ip_address = local.FW_IP
#   }

#   lifecycle {
#     ignore_changes = all
#   }

#   tags = local.tags
  
# }


# resource "azurerm_subnet_route_table_association" "spoke-client" {
#   subnet_id      = azurerm_subnet.azurespoke-default.id
#   route_table_id = azurerm_route_table.spoke-client.id
# }

# resource "azurerm_subnet_route_table_association" "spoke-client2" {
#   subnet_id      = azurerm_subnet.azurespoke-endpoint.id
#   route_table_id = azurerm_route_table.spoke-client.id
# }

