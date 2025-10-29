terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 4.50.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
    subscription_id = "<subscription-id>"
    features {}
}


data "azurerm_resource_group" "rg" {
  name     = "<resource-group-name>"
}

data "azurerm_log_analytics_workspace" "law" {
  name                = "<log-analytics-workspace-name>"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_log_analytics_solution" "example" {
  solution_name         = "WindowsEventForwarding"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  workspace_resource_id = data.azurerm_log_analytics_workspace.law.id
  workspace_name        = data.azurerm_log_analytics_workspace.law.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/WindowsEventForwarding"
  }
}


data "azurerm_monitor_data_collection_endpoint" "dce" {
  name                = "<data-collection-endpoint-name>"
  resource_group_name = data.azurerm_resource_group.rg.name

}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                        = "<data-collection-rule-name>"
  resource_group_name         = data.azurerm_resource_group.rg.name
  location                    = data.azurerm_resource_group.rg.location
  data_collection_endpoint_id = data.azurerm_monitor_data_collection_endpoint.dce.id
  kind                        = "Windows"

  destinations {
    log_analytics {
      workspace_resource_id = data.azurerm_log_analytics_workspace.law.id      
      name                  = "example-destination-log"
    }

  }


  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["example-destination-log"]
    transform_kql = "source"
    output_stream = "Microsoft-Event"
  }

   data_sources {

    windows_event_log {
      streams        = ["Microsoft-Event"]
            x_path_queries = [
        "Application!*",
        "Security!*",
        "System!*",
        "Microsoft-Windows-Sysmon/Operational!*"        
        ]

        # Filtering is possible using XPath queries, examples:
        #  "Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",
        #  "Security!*[System[(band(Keywords,13510798882111488))]]",
        #  "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]"
        # More info here: https://learn.microsoft.com/en-us/azure/azure-monitor/vm/data-collection-windows-events

      name           = "example-datasource-wineventlog"
    }
  
  }

  description = "data collection rule example"
  tags = {
    foo = "bar"
  }
  
}