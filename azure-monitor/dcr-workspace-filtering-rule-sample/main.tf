resource "azurerm_monitor_data_collection_rule" "rule1" {
  name                        = "Filter-logs-at-workspace-level"
  resource_group_name         = azurerm_resource_group.rg0.name
  location                    = azurerm_resource_group.rg0.location
  # Notice the kind, which is different from the other examples
  # This should be configured under its own DCR
  kind                        = "WorkspaceTransforms"
  
  
    # Which Log Analytics workspace does this relate to
    destinations {
      log_analytics {
        workspace_resource_id = data.azurerm_log_analytics_workspace.law.id
        name                  = "myworkspace"
      }
    }


    data_flow {
      streams      = ["Microsoft-Table-Syslog"]
      destinations = ["myworkspace"]
      transform_kql = "source | where ProcessName == 'systemd'"
    }


    description = "DCR to filter incoming logs in to the Syslog table at the service level"

}