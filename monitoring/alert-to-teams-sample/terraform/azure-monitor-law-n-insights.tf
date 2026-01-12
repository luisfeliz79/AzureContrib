resource "azurerm_log_analytics_workspace" "law" {
  name                = local.support_loganalytics_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"

  tags = local.tags
}

resource "azurerm_application_insights" "ai" {
  name                = local.support_appinsights_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"

  local_authentication_disabled = false

}