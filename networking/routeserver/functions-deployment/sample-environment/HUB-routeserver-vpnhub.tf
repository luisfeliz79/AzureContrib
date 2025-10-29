module "route-server" {

  count = local.include_route_server ? 1 : 0

  source = "../modules/route-server"

  name                             = "hub-rs"
  region                           = local.region
  resource_group_name              = azurerm_resource_group.azuregw.name
  subnet_id                        = azurerm_subnet.azuregw-rs.id
  enable_branch_to_branch_traffic = true

  list_of_bgp_connections = [
    {
      name     = local.vm_azuregw_nva_name
      peer_asn = 65001
      peer_ip  = module.azuregw-nva-vm.VM_IP
    },
    #Uncomment if you have a second NVA connection
    {
      name     = local.vm_azuregw_nva2_name
      peer_asn = 65001
      peer_ip  = module.azuregw-nva-vm2.VM_IP
    }
  ]
  tags = local.tags

}


# resource "azurerm_public_ip" "rslabpip1" {
#   name                = "hub-rs-pip"
#   location            = local.region
#   resource_group_name = azurerm_resource_group.azuregw.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_route_server" "rs1" {
#   name                             = "hub-rs"
#   location                         = local.region
#   resource_group_name              = azurerm_resource_group.azuregw.name
#   sku                              = "Standard"
#   public_ip_address_id             = azurerm_public_ip.rslabpip1.id
#   subnet_id                        = azurerm_subnet.azuregw-rs.id
#   branch_to_branch_traffic_enabled = true
# }

# resource "azurerm_route_server_bgp_connection" "nvaconnection1" {
#   name            = local.vm_azuregw_nva_name
#   route_server_id = azurerm_route_server.rs1.id
#   peer_asn        = 65001
#   peer_ip         = module.azuregw-nva-vm.VM_IP
# }

# # resource "azurerm_route_server_bgp_connection" "nvaconnection2" {
# #   name            = local.vm_azuregw_nva2_name
# #   route_server_id = azurerm_route_server.rs1.id
# #   peer_asn        = 65001
# #   peer_ip         = module.azuregw-nva-vm2.VM_IP
# # }
