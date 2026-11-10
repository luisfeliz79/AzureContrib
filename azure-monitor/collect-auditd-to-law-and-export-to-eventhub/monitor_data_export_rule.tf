# Configure RBAC role for the data export rule
resource "azurerm_role_assignment" "data_export_rule_rbac" {
  scope                = azurerm_eventhub_namespace.ehns.id
  role_definition_name = "Azure Event Hubs Data Owner"
  principal_id         = azurerm_log_analytics_workspace.law.identity[0].principal_id
}


resource "azurerm_log_analytics_data_export_rule" "export1" {
  name                        = "export1"
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  resource_group_name         = azurerm_resource_group.rg0.name
  destination_resource_id =  azurerm_eventhub.auditd.id

  table_names = ["AuditD_CL"]

  enabled = true

  depends_on = [ azurerm_role_assignment.data_export_rule_rbac ]
}