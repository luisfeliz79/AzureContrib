module "eventhub_diagnostics" {
  source = "./modules/diagnostics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  target_resource_id = azurerm_eventhub_namespace.ehns.id
}