# This rule collects syslog from a specific Facility and Severity level and sends it to a Log Analytics workspace, and process name

# Use this Azure Policy to assign this Data collection rule to VMs at scale
# https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F2ea82cdd-f2e8-4500-af75-67a2e084ca74

resource "azurerm_monitor_data_collection_rule" "rule1" {
  name                        = "send-filtered-syslog-to-workspace"
  resource_group_name         = azurerm_resource_group.rg0.name
  location                    = local.region0
  data_collection_endpoint_id = data.azurerm_monitor_data_collection_endpoint.region0dce.id
  
    # Which Log Analytics workspace to send data to
    destinations {
      log_analytics {
        workspace_resource_id = data.azurerm_log_analytics_workspace.law.id
        name                  = data.azurerm_log_analytics_workspace.law.name
      }
    }

    # Data_source blocks define which data sources to collect from
    data_sources {

      syslog {
        facility_names = ["daemon"]
        log_levels     = ["Info"]
        name           = "datasource-syslog"
        streams        = ["Microsoft-Syslog"]
      }

    }

    # Data flow connects sources to destinations
    data_flow {
      streams      = ["Microsoft-Syslog"]
      destinations = [data.azurerm_log_analytics_workspace.law.name]
      output_stream = "Microsoft-Syslog"
      transform_kql = "source | where ProcessName == 'systemd' or ProcessName == 'dockerd'"
    }


    description = "DCR for Filtered Syslog to Log Analytics Workspace"

    depends_on = [
      data.azurerm_log_analytics_workspace.law
    ]
}