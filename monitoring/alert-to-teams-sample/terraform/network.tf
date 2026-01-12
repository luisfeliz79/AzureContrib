resource "azurerm_virtual_network" "vnet" {
  address_space                  = ["10.0.0.0/16"]
  #dns_servers                    = []
  location                       = azurerm_resource_group.rg.location
  name                           = "vnet-logic-apps"
  resource_group_name            = azurerm_resource_group.rg.name

  tags = local.tags
}


resource "azurerm_subnet" "asev3" {
  name                 = "app-service-environment"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "Microsoft.Web.hostingEnvironments"
    service_delegation {
      name    = "Microsoft.Web/hostingEnvironments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  default_outbound_access_enabled = false
  
}




resource "azurerm_network_security_group" "app-service-environment" {
  name                = "nsg-asev3"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule  {
    name                       = "Allow-HTTPs-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${local.user_ip_address}/32"
    destination_address_prefix = azurerm_subnet.asev3.address_prefixes[0]
  }

  security_rule  {
    name                       = "Allow-Load-Balancer-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = azurerm_subnet.asev3.address_prefixes[0]
  }

  security_rule  {
    name                       = "Allow-Action-Groups-Inbound"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "ActionGroup"
    destination_address_prefix = azurerm_subnet.asev3.address_prefixes[0]
  }

  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "asev3-nsg-assoc" {
  subnet_id                 = azurerm_subnet.asev3.id
  network_security_group_id = azurerm_network_security_group.app-service-environment.id
}

resource "azurerm_route_table" "asev3-rt" {
  name                = "rt-asev3"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name           = "to-firewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = local.firewall_private_ip
  }

  route {
    name           = "To-ActionGroup"
    address_prefix = "ActionGroup"
    next_hop_type  = "Internet"
  }

  
  route {
    name           = "To-UserIPForTestingOnly"
    address_prefix = "${local.user_ip_address}/32"
    next_hop_type  = "Internet"
  }
  
  


  tags = local.tags
}

resource "azurerm_subnet_route_table_association" "asev3-rt-assoc" {
  subnet_id      = azurerm_subnet.asev3.id
  route_table_id = azurerm_route_table.asev3-rt.id
}



resource "azurerm_subnet" "endpoints" {
  address_prefixes                              = ["10.0.1.0/27"]
  default_outbound_access_enabled               = false
  name                                          = "endpoints"
  resource_group_name                           = azurerm_resource_group.rg.name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_network_security_group" "nsg-endpoints" {
  name                = "nsg-endpoints"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "endpoints-nsg-assoc" {
  subnet_id                 = azurerm_subnet.endpoints.id
  network_security_group_id = azurerm_network_security_group.nsg-endpoints.id
}

resource "azurerm_private_endpoint" "blobpe" {
  custom_network_interface_name = "bloppe-nic"
  location                      = azurerm_resource_group.rg.location
  name                          = "bloppe"
  resource_group_name           = azurerm_resource_group.rg.name
  subnet_id                     = azurerm_subnet.endpoints.id
  tags                  = local.tags
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
  private_service_connection {
    is_manual_connection              = false
    name                              = "bloppe"
    private_connection_resource_id    = azurerm_storage_account.sa.id
    subresource_names                 = ["blob"]
  }

}
resource "azurerm_private_endpoint" "queuepe" {
  custom_network_interface_name = "queuePe-nic"
  location                      = azurerm_resource_group.rg.location
  name                          = "queuePe"
  resource_group_name           = azurerm_resource_group.rg.name
  subnet_id                     = azurerm_subnet.endpoints.id
  tags                  = local.tags
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.queue.id]
  }
  private_service_connection {
    is_manual_connection              = false
    name                              = "queuePe"
    private_connection_resource_id    = azurerm_storage_account.sa.id
    subresource_names                 = ["queue"]
  }
}
resource "azurerm_private_endpoint" "tablepe" {
  custom_network_interface_name = "tablespe-nic"
  location                      = azurerm_resource_group.rg.location
  name                          = "tablespe"
  resource_group_name           = azurerm_resource_group.rg.name
  subnet_id                     = azurerm_subnet.endpoints.id
  tags                  = local.tags
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.table.id]
  }
  private_service_connection {
    is_manual_connection              = false
    name                              = "tablespe"
    private_connection_resource_id    = azurerm_storage_account.sa.id
    subresource_names                 = ["table"]
  }
}

resource "azurerm_private_endpoint" "filepe" {
  custom_network_interface_name = "filepe-nic"
  location                      = azurerm_resource_group.rg.location
  name                          = "filepe"
  resource_group_name           = azurerm_resource_group.rg.name
  subnet_id                     = azurerm_subnet.endpoints.id
  tags                          = local.tags
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
  }
  private_service_connection {
    is_manual_connection              = false
    name                              = "filepe"
    private_connection_resource_id    = azurerm_storage_account.sa.id
    subresource_names                 = ["file"]
  }
}


resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "a7amrh7bxn46s"
  private_dns_zone_name = "privatelink.blob.core.windows.net"
  registration_enabled  = false
  resolution_policy     = "Default"
  resource_group_name   = azurerm_resource_group.rg.name
  tags                  = local.tags
  virtual_network_id    = azurerm_virtual_network.vnet.id
  depends_on = [
    azurerm_private_dns_zone.blob,
  ]
}
resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

}

resource "azurerm_private_dns_zone_virtual_network_link" "queue" {
  name                  = "a7amrh7bxn46s"
  private_dns_zone_name = "privatelink.queue.core.windows.net"
  registration_enabled  = false
  resolution_policy     = "Default"
  resource_group_name   = azurerm_resource_group.rg.name
  tags                  = local.tags
  virtual_network_id    = azurerm_virtual_network.vnet.id
  depends_on = [
    azurerm_private_dns_zone.queue,
  ]
}
resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "a7amrh7bxn46s"
  private_dns_zone_name = "privatelink.table.core.windows.net"
  registration_enabled  = false
  resolution_policy     = "Default"
  resource_group_name   = azurerm_resource_group.rg.name
  tags                  = local.tags
  virtual_network_id    = azurerm_virtual_network.vnet.id
  depends_on = [
    azurerm_private_dns_zone.table,
  ]
}

resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  name                  = "a7amrh7bxn46s"
  private_dns_zone_name = "privatelink.file.core.windows.net"
  registration_enabled  = false
  resolution_policy     = "Default"
  resource_group_name   = azurerm_resource_group.rg.name
  tags                  = local.tags
  virtual_network_id    = azurerm_virtual_network.vnet.id
  depends_on = [
    azurerm_private_dns_zone.file,
  ]
}

