resource "azurerm_public_ip" "rslabpip1" {
  name                = "${var.name}-pip"
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

    lifecycle {
    ignore_changes = all
      #subnet_id,ip_tags # This is needed to avoid the public IP being recreated
    #]
  }
}

resource "azurerm_route_server" "rs1" {
  name                             = var.name
  location                         = var.region
  resource_group_name              = var.resource_group_name
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.rslabpip1.id
  subnet_id                        = var.subnet_id
  branch_to_branch_traffic_enabled = var.enable_branch_to_branch_traffic

  lifecycle {
    ignore_changes = all
      #subnet_id,ip_tags # This is needed to avoid the public IP being recreated
    #]
  }
}

resource "azurerm_route_server_bgp_connection" "bgpconnections" {
  for_each = { for conn in var.list_of_bgp_connections : conn.name => conn }

  name            = each.value.name
  route_server_id = azurerm_route_server.rs1.id
  peer_asn        = each.value.peer_asn
  peer_ip         = each.value.peer_ip

}

# resource "azurerm_route_server_bgp_connection" "nvaconnection2" {
#   name            = local.vm_azuregw_nva2_name
#   route_server_id = azurerm_route_server.rs1.id
#   peer_asn        = 65001
#   peer_ip         = module.azuregw-nva-vm2.VM_IP
# }
