resource "azurerm_public_ip" "rslabpip1" {
  name                = "routeserver-hub-ip"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.hub_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "rs1" {
  name                             = "hub-routeserver"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.hub_rg.name
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.rslabpip1.id
  subnet_id                        = azurerm_subnet.hub_RouteServer.id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "nvaconnection" {
  name            = local.nva_name
  route_server_id = azurerm_route_server.rs1.id
  peer_asn        = 65501
  peer_ip         = local.nva_internal_nic_ip
}
