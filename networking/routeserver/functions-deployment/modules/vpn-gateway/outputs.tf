output "vpn_gw1_public_ip" {
  value = azurerm_public_ip.gwlabpip1.ip_address
}

output "vpn_gw2_public_ip" {
  value = azurerm_public_ip.gwlabpip2.ip_address
}

output "gateway_id" {
  value = azurerm_virtual_network_gateway.gw1.id
}