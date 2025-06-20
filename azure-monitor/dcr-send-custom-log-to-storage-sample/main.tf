resource "azurerm_monitor_data_collection_rule" "rule1" {
  name                        = "send-custom-logs-to-storage-account"
  resource_group_name         = azurerm_resource_group.rg0.name
  location                    = azurerm_resource_group.rg0.location
  # Notice the kind, which is different from the other examples
  # This should be configured under its own DCR
  kind                        = "AgentDirectToStore"

    # Destinations define where to send log data to.
    destinations {
      # this RBAC permissions are needed: Storage Blob Data Contributor
      # for the VM/VMSS identity to write to the storage account
      storage_blob_direct {
        storage_account_id = azurerm_storage_account.sa1.id
        container_name     = azurerm_storage_container.container1.name
        name               = "example-destination-storage"
      }
    }

    # Data_source blocks define which data sources to collect from
    data_sources {
      log_file {
        name          = "audit-log"        
        format        = "text"
        streams       = ["Custom-Text-logs"]
        file_patterns = ["//var//log/audit/audit.log"]
        settings {
          text {
            record_start_timestamp_format = "ISO 8601"
          }
        }
      }
    }

    # Data_flow blocks define how to process and send the data
    data_flow {
      streams      = ["Custom-Text-logs"]
      destinations = ["example-destination-storage"]      
    }


    description = "DCR for Custom log sent to storage account"

    depends_on = [
      azurerm_storage_account.sa1
    ]
}