
# Create an Azure Monitor action group that sends to a EventHub Namespace and Hub
resource "azurerm_monitor_action_group" "ehactiongroup" {
  name                = "eventhub-action-group"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "ehgroup"
  event_hub_receiver {
    event_hub_namespace = azurerm_eventhub_namespace.ehns.name
    event_hub_name = azurerm_eventhub.hub1.name
    name = azurerm_eventhub.hub1.name
    use_common_alert_schema = true
        
  }
}
