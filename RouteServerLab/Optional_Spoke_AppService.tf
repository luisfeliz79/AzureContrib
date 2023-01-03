resource "azurerm_service_plan" "plan1" {
  name                    = "rslabprivateapp-plan"
  location                = var.location
  resource_group_name     = azurerm_resource_group.spoke_rg.name
  
  os_type                 = "Linux"
  sku_name                = "B1"
}

resource "azurerm_windows_web_app" "app1" {
  name                 = "rslabprivateapp"
  location             = var.location
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  service_plan_id      = azurerm_service_plan.plan1.id

  site_config {}
}


resource "azurerm_private_dns_zone" "webapps_zone" {
  name                 = "privatelink.azurewebsites.net"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
}



resource "azurerm_private_endpoint" "app-endpoint" {
  name                = "privateapp-endpoint"
  location            = var.location
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  subnet_id           = azurerm_subnet.spoke_Apps.id

  private_service_connection {
    name                           = "app-private-link-connection"
    private_connection_resource_id = azurerm_windows_web_app.app1.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                          = azurerm_private_dns_zone.webapps_zone.name
    private_dns_zone_ids          = [ azurerm_private_dns_zone.webapps_zone.id ]
  }

}


