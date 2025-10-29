
resource "azurerm_network_security_group" "nsg-default" { 
  name                        = "molabs-nsg-default"
  location                    = azurerm_virtual_network.azuregw.location
  resource_group_name         = azurerm_virtual_network.azuregw.resource_group_name

   security_rule {
        
        name                       = "allow-internal-nets"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "10.0.0.0/8"
        destination_address_prefix = "10.0.0.0/8"
    }

  tags = local.tags
}


resource "azurerm_network_security_group" "nva-external" { 
  name                        = "molabs-onprem-nva-external"
  location                    = azurerm_virtual_network.onprem.location
  resource_group_name         = azurerm_virtual_network.onprem.resource_group_name

    dynamic "security_rule" {
      for_each = local.include_vnetgw ? [1] : []
        content {     
          name                        = "AllowUDP500"
          priority                    = 100
          direction                   = "Inbound"
          access                      = "Allow"
          protocol                    = "Udp"
          source_port_range           = "*"
          destination_port_range      = "500"
          source_address_prefixes     = ["${module.vpngateway[0].vpn_gw1_public_ip}/32","${module.vpngateway[0].vpn_gw2_public_ip}/32"]
          destination_address_prefix  = "*"
        }
    }

    dynamic "security_rule" {
    for_each = local.include_vnetgw ? [1] : []
      content {      
        name                        = "AllowUDP4500"
        priority                    = 101
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Udp"
        source_port_range           = "*"
        destination_port_range      = "4500"
        source_address_prefixes     = ["${module.vpngateway[0].vpn_gw1_public_ip}/32","${module.vpngateway[0].vpn_gw2_public_ip}/32"]
        destination_address_prefix  = "*"
      }
    }

    # security_rule {      
    #   name                        = "AllowRDP"
    #   priority                    = 102
    #   direction                   = "Inbound"
    #   access                      = "Allow"
    #   protocol                    = "Tcp"
    #   source_port_range           = "*"
    #   destination_port_range      = "3389"
    #   source_address_prefix       = "${local.user_ip_address}/32"
    #   destination_address_prefix  = "*"
    # }

            

  tags = local.tags
}