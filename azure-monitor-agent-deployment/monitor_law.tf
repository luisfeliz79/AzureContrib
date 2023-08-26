# Create a Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${local.prefix}"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

