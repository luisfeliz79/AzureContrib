# References:
# https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-send-data-to-event-hubs-and-storage?tabs=linux%2Cwindows-1
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_data_collection_rule#event_hub_direct

resource "azurerm_monitor_data_collection_rule" "ehrule1" {
  name                        = "custom-log-to-eventhub-dcr2"
  resource_group_name         = azurerm_resource_group.rg0.name
  location                    = local.region0
  kind                       = "AgentDirectToStore"

    # Which Event hubs to send data to
    destinations {
      event_hub_direct {
        event_hub_id = azurerm_eventhub.eh.id
        name = azurerm_eventhub.eh.name
      }
    }

    # Data_source blocks define which data sources to collect from
    data_sources {

      # This collects all syslog, it is possible to filter by facility and log level
      syslog {
        facility_names = [ "auth",
                        "authpriv",
                        "cron",
                        "daemon",
                        "mark",
                        "kern",
                        "local0",
                        "local1",
                        "local2",
                        "local3",
                        "local4",
                        "local5",
                        "local6",
                        "local7",
                        "lpr",
                        "mail",
                        "news",
                        "syslog",
                        "user",
                        "uucp"]
        log_levels     = [                        "Debug",
                        "Info",
                        "Notice",
                        "Warning",
                        "Error",
                        "Critical",
                        "Alert",
                        "Emergency"]
        name           = "syslogDataSource"
        streams = [ "Microsoft-Syslog" ]
      }

      # For future use
      # # This collects a log file specifically for cases where the logs are not be sent to Syslog
      # # You can define multiple log_file blocks to collect from multiple files
      # log_file {
      #   name          = "audit-log"
      #   format        = "text"
      #   streams       = ["Custom-audit-log"]
      #   file_patterns = ["//var//log/audit/audit.log"]
      #   settings {
      #     text {
      #       record_start_timestamp_format = "ISO 8601"
      #     }
      #   }
      # }

    }


    # Data_flow blocks define which streams to send to which destinations
    
    data_flow {
      streams      = ["Microsoft-Syslog"]
      destinations = [azurerm_eventhub.eh.name]
    }

    # For future use
    # data_flow {
    #   streams      = ["Custom-audit-log"]
    #   destinations = [azurerm_eventhub.eh.name]
    # }


    description = "DCR for Custom log and sending to Event Hub directly"

    depends_on = [
      azurerm_eventhub.eh
    ]
}

# RBAC required for Event Hubs
resource "azurerm_role_assignment" "sendperms" {
  principal_id                     = azurerm_user_assigned_identity.uaid1.principal_id
  role_definition_name             = "Azure Event Hubs Data Sender"
  scope                            = azurerm_eventhub.eh.id
  skip_service_principal_aad_check = true
}