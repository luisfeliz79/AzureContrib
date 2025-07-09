module "blob_dns" {
  source = "../modules/private-dns-zone"

  zone_name = "privatelink.blob.core.windows.net"
  zone_rg   = azurerm_resource_group.azuregw.name
  vnet_ids  = [azurerm_virtual_network.azuregw.id]
}

module "file_dns" {
  source = "../modules/private-dns-zone"

  zone_name = "privatelink.file.core.windows.net"
  zone_rg   = azurerm_resource_group.azuregw.name
  vnet_ids  = [azurerm_virtual_network.azuregw.id]
}

module "table_dns" {
  source = "../modules/private-dns-zone"

  zone_name = "privatelink.table.core.windows.net"
  zone_rg   = azurerm_resource_group.azuregw.name
  vnet_ids  = [azurerm_virtual_network.azuregw.id]
}

module "queue_dns" {
  source = "../modules/private-dns-zone"

  zone_name = "privatelink.queue.core.windows.net"
  zone_rg   = azurerm_resource_group.azuregw.name
  vnet_ids  = toset([azurerm_virtual_network.azuregw.id])
}

module "pe_storage" {
  source = "../modules/private-endpoint-storage-account"

  sa_name                = azurerm_storage_account.sa.name
  sa_id                  = azurerm_storage_account.sa.id
  region                 = local.region
  resource_group_name    = azurerm_resource_group.azuregw.name
  endpoints_subnet_id    = azurerm_subnet.azuregw-endpoints.id
  zone_rg                = azurerm_resource_group.azuregw.name

  depends_on = [ module.blob_dns, module.file_dns, module.table_dns, module.queue_dns ]
}