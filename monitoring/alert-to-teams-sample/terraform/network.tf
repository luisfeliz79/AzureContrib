resource "azurerm_virtual_network" "vnet" {
  address_space                  = ["10.0.0.0/16"]
  #dns_servers                    = []
  location                       = azurerm_resource_group.rg.location
  name                           = "vnet-logic-apps"
  resource_group_name            = azurerm_resource_group.rg.name
  tags = local.tags
}

resource "azurerm_subnet" "logic-apps" {
  address_prefixes                              = ["10.0.0.0/27"]
  default_outbound_access_enabled               = true
  name                                          = "logic-apps"
  resource_group_name                           = azurerm_resource_group.rg.name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  delegation {
    name = "delegation"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      name    = "Microsoft.Web/serverFarms"
    }
  }
  depends_on = [
    azurerm_virtual_network.vnet,
  ]
}

resource "azurerm_subnet" "endpoints" {
  address_prefixes                              = ["10.0.1.0/27"]
  default_outbound_access_enabled               = true
  name                                          = "endpoints"
  resource_group_name                           = azurerm_resource_group.rg.name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
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

