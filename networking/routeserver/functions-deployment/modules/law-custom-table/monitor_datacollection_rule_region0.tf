# This is an all in one rule that collects syslog, perf counters, and custom logs
# It is possible to break this up into multiple rules, but this reduces the number DCRs required."

# Use this Azure Policy to assign this Data collection rule to VMs at scale
# https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F2ea82cdd-f2e8-4500-af75-67a2e084ca74

resource "azurerm_monitor_data_collection_rule" "rule1" {
  name                        = var.dcr_name
  resource_group_name         = var.resource_group_name
  location                    = var.region
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.region0dce.id
  
    # Which Log Analytics workspace to send data to
    destinations {
      log_analytics {
        workspace_resource_id = var.log_analytics_workspace_id
        name                  = var.log_analytics_workspace_name
      }
    }

    stream_declaration  {
          stream_name = "Custom-log"

        dynamic "column" {
          iterator = each
          for_each = var.custom_table_columns
          content {
            name = each.value.name
            type = lower(each.value.type)
          }
          
        }
          
        }
  

   

    # Data_flow blocks define which streams to send to which destinations

    data_flow {
      streams      = ["Custom-log"]
      destinations = [var.log_analytics_workspace_name]
      #transform_kql = "source | where RawData contains 'SERVICE_STOP'"
      output_stream = "Custom-${var.custom_table_name}"
    }


    description = "DCR for Custom log send to Log Analytics Workspace"

  depends_on = [ azapi_resource.lawtable,azurerm_monitor_data_collection_endpoint.region0dce ]

}