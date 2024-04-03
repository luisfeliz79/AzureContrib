resource "azurerm_eventhub_namespace" "ehns" {
  name                = local.support_eventhub_name  
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 1  
  minimum_tls_version = "1.2"
  public_network_access_enabled = false

  network_rulesets  {
    default_action = "Deny"
    public_network_access_enabled = false
    trusted_service_access_enabled = true
  }

}

resource "azurerm_eventhub" "hub1" {
  name                = "incoming-alerts1"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 1
  message_retention   = 1
}
