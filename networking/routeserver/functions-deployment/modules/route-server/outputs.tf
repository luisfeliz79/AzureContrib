output "id" {
  value = azurerm_route_server.rs1.id
}

output "route_server_bgp_ip1" {
  value = azurerm_route_server.rs1.virtual_router_ips
}

# output "route_server_bgp_ip2" {
#   value = azurerm_route_server.rs1.virtual_router_ips[1].ip_address
# }