
resource "azurerm_private_endpoint" "eventhub-endpoint" {
  name                = "eventhub-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoints_subnet.id

  private_service_connection {
    name                           = "pe-connection-eh-${local.support_eventhub_name}"
    private_connection_resource_id = azurerm_eventhub_namespace.ehns.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                          = "pe-connection-eh-${local.support_eventhub_name}"
    private_dns_zone_ids          = [ azurerm_private_dns_zone.eventhub_zone.id ]
  }

  tags = local.tags
}
