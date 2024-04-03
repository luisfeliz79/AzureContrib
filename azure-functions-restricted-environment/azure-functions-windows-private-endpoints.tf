
resource "azurerm_private_endpoint" "webapps-endpoint" {
  name                = "webapps-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoints_subnet.id

  private_service_connection {
    name                           = "pe-connection-web-${local.rg_prefix}-funcwin"
    private_connection_resource_id = azurerm_windows_function_app.funcapp.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                          = "pe-connection-web-${local.rg_prefix}-funcwin"
    private_dns_zone_ids          = [ azurerm_private_dns_zone.webapp_zone.id ]
  }

  tags = local.tags
}
