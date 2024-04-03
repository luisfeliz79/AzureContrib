
# Private Endpoints setup
resource "azurerm_private_endpoint" "peblob" {
  name                = "pe-blob-${local.support_storageaccount_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoints_subnet.id

  private_service_connection {
    name                           = "pe-connection-blob-${local.support_storageaccount_name}"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.blob.name
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

resource "azurerm_private_endpoint" "pefile" {
  name                = "pe-file-${local.support_storageaccount_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoints_subnet.id
  private_service_connection {
    name                           = "pe-connection-file-${local.support_storageaccount_name}"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.file.name
    private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
  }
}

resource "azurerm_private_endpoint" "petable" {
  name                = "pe-table-${local.support_storageaccount_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoints_subnet.id
  private_service_connection {
    name                           = "pe-connection-table-${local.support_storageaccount_name}"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }
  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.table.name
    private_dns_zone_ids = [azurerm_private_dns_zone.table.id]
  }
}

resource "azurerm_private_endpoint" "pequeue" {
  name                = "pe-queue-${local.support_storageaccount_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoints_subnet.id
  private_service_connection {
    name                           = "pe-connection-queue-${local.support_storageaccount_name}"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["queue"]
  }
  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.queue.name
    private_dns_zone_ids = [azurerm_private_dns_zone.queue.id]
  }
}