# This is an all in one rule that collects syslog, perf counters, and custom logs
# It is possible to break this up into multiple rules, but this reduces the number DCRs required."

# Use this Azure Policy to assign this Data collection rule to VMs at scale
# https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F2ea82cdd-f2e8-4500-af75-67a2e084ca74

resource "azurerm_monitor_data_collection_rule" "rule1" {
  name                        = "syslogs-and-metrics-dcr"
  resource_group_name         = azurerm_resource_group.rg0.name
  location                    = local.region0
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.region0dce.id
  
    # Which Log Analytics workspace to send data to
    destinations {
      log_analytics {
        workspace_resource_id = azurerm_log_analytics_workspace.law.id
        name                  = azurerm_log_analytics_workspace.law.name
      }
    }

    # Data_source blocks define which data sources to collect from
    data_sources {

      # This collects all syslog, it is possible to filter by facility and log level
      syslog {
        facility_names = ["*"]
        log_levels     = ["*"]
        name           = "datasource-syslog"
      }

      # This collects all perf counters, it is possible to filter by counter name
      performance_counter {
        streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
        sampling_frequency_in_seconds = 60
        #counter_specifiers            = ["Processor(*)\\% Processor Time"]
        counter_specifiers            = ["*"]
        name                          = "datasource-perfcounters"
      }

      # This collects a log file specifically for cases where the logs are not be sent to Syslog
      # You can define multiple log_file blocks to collect from multiple files
      log_file {
        name          = "audit-log"
        format        = "text"
        streams       = ["Custom-audit-log"]
        file_patterns = ["//var//log/audit/audit.log"]
        settings {
          text {
            record_start_timestamp_format = "ISO 8601"
          }
        }
      }
    }

    # Stream_declaration blocks define the schema of the log_files
    stream_declaration {
        stream_name = "Custom-audit-log"
        column {
          name = "TimeGenerated"
          type = "datetime"
        }
        column {
          name = "RawData"
          type = "string"
        }

      }

    # Data_flow blocks define which streams to send to which destinations
    data_flow {
      streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf"]
      destinations = [azurerm_log_analytics_workspace.law.name]
    }

    # You can have multiple data_flow blocks going to different places or with different options
    # In this example, this log file is being sent specifically to a custom table
    # called "AuditD_CL" as specified in the output_stream
    # .. The prefix "Custom-" is required for Custom Tables
    data_flow {
      streams      = ["Custom-audit-log"]
      destinations = [azurerm_log_analytics_workspace.law.name]
      transform_kql = "source"
      output_stream = "Custom-AuditD_CL"
    }


    description = "DCR for Syslog, Perf Counters, and custom log"
    tags = {
      foo = "bar"
    }
    depends_on = [
      azurerm_log_analytics_workspace.law
    ]
}