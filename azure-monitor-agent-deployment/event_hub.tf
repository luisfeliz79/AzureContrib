resource "azurerm_eventhub_namespace" "ehns" {
  name                = "${local.prefix}-eh-ns"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name
  sku                 = "Standard"
  capacity            = 1
}

resource "azurerm_eventhub" "eh" {
  name                = "monitoring"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  resource_group_name = azurerm_resource_group.rg0.name
  partition_count     = 1
  message_retention   = 1
}
