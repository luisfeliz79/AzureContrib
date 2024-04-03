
resource "azurerm_private_endpoint" "keyvault-endpoint" {
  name                = "keyvault-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoints_subnet.id

  private_service_connection {
    name                           = "pe-connection-kv-${local.support_keyvault_name}"
    private_connection_resource_id = azurerm_key_vault.support_kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                          = "pe-connection-kv-${local.support_keyvault_name}"
    private_dns_zone_ids          = [ azurerm_private_dns_zone.keyvault_zone.id ]
  }

  tags = local.tags
}
