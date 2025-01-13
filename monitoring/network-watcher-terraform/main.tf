# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_connection_monitor

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">=4.15.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
    features {}
    subscription_id = "<subscription_id>"
}

# Example, reading in an existinv VM or VMSS Flexible Instance
data "azurerm_virtual_machine" "example-vm-source" {
  name                = "vmss-api-gw_ab7c9dec"
  resource_group_name = "vwan-app"
}

# Example, reading in an existinv VMSS Uniform resource
data "azurerm_virtual_machine_scale_set" "example-vmss-destination" {
  name                = "vmss-java-app"
  resource_group_name = "vwan-app"
}

# Example, reading in an existinv Log Analytics Workspace
data "azurerm_log_analytics_workspace" "example" {
    name                = "netwatcher-law"
    resource_group_name = "vwan-app"    
}

# Example, reading in an existinv Network Watcher
data "azurerm_network_watcher" "example" {
    name                = "NetworkWatcher_westus"
    resource_group_name = "NetworkWatcherRG"
}


# Example of installing the Network Watcher Agent on a Virtual Machine 
resource "azurerm_virtual_machine_extension" "example-source" {
  name                       = "NetworkWatcher"
  virtual_machine_id = data.azurerm_virtual_machine.example-vm-source.id
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentLinux"
  type_handler_version       = "1.4"
  auto_upgrade_minor_version = true
}


# Example of installing the Network Watcher Agent on a Virtual Machine scale set
# NOTE: VMSS instances will need upgrading to complete the setup
#
resource "azurerm_virtual_machine_scale_set_extension" "example-vmss-destination" {
  name                       = "NetworkWatcher"
virtual_machine_scale_set_id = data.azurerm_virtual_machine_scale_set.example-vmss-destination.id
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentLinux"
  type_handler_version       = "1.4"
  auto_upgrade_minor_version = true
}


# Example ICMP Monitor
resource "azurerm_network_connection_monitor" "example-icmp-monitor" {
  name               = "example-ping-monitor"
  network_watcher_id = data.azurerm_network_watcher.example.id
  location           = data.azurerm_network_watcher.example.location

  endpoint {
    name               = "source"
    target_resource_id = data.azurerm_virtual_machine.example-vm-source.id
  }

  endpoint {
    name    = "destination"
    address = "10.50.0.4" # or DNS domain name
    target_resource_type = "ExternalAddress"
  }

  test_configuration {
    name                      = "ping"
    protocol                  = "Icmp"
    test_frequency_in_seconds = 60

    success_threshold {
        checks_failed_percent = "1"
        round_trip_time_ms =  "20"
    }

  }

  test_group {
    name                     = "example-test-group"
    destination_endpoints    = ["destination"]
    source_endpoints         = ["source"]
    test_configuration_names = ["ping"]
  }

  notes = "examplenote"

  output_workspace_resource_ids = [data.azurerm_log_analytics_workspace.example.id]

  
}


# Example TCP Monitor
resource "azurerm_network_connection_monitor" "example-tcp-monitor" {
  name               = "example-tcp-monitor"
  network_watcher_id = data.azurerm_network_watcher.example.id
  location           = data.azurerm_network_watcher.example.location

  endpoint {
    name               = "source"
    target_resource_id = data.azurerm_virtual_machine.example-vm-source.id
  }

  endpoint {
    name    = "destination"
    address = "10.50.0.4" # or DNS domain name
    target_resource_type = "ExternalAddress"
  }

  test_configuration {
    name                      = "tcp-test"
    protocol                  = "Tcp"
    test_frequency_in_seconds = 60

    tcp_configuration {
      port = 8080
    }

    success_threshold {
        checks_failed_percent = "1"
        round_trip_time_ms =  "20"
    }
  }

  test_group {
    name                     = "example-test-group"
    destination_endpoints    = ["destination"]
    source_endpoints         = ["source"]
    test_configuration_names = ["tcp-test"]
  }

  notes = "examplenote"

  output_workspace_resource_ids = [data.azurerm_log_analytics_workspace.example.id]

  
}


# Example HTTP Monitor
resource "azurerm_network_connection_monitor" "example-http-monitor" {
  name               = "example-http-monitor"
  network_watcher_id = data.azurerm_network_watcher.example.id
  location           = data.azurerm_network_watcher.example.location

  endpoint {
    name               = "source"
    target_resource_id = data.azurerm_virtual_machine.example-vm-source.id
  }

  endpoint {
    name    = "destination"    
    address = "10.50.0.4" # or DNS domain name
    # Note, we should are able to set a full url in the address field via the Azure Portal
    # However, the AzureRM module has not been updated to do this yet.
    # So only use a DNS name or IP address for now

    target_resource_type = "ExternalAddress"

  }

  test_configuration {
    name                      = "http-test"
    protocol                  = "Http"
    test_frequency_in_seconds = 60

    http_configuration {
      port = 8080
      method = "Get"
      valid_status_code_ranges = ["200-500"]
      #path = "/time"
      #prefer_https = true
    }

    success_threshold {
        checks_failed_percent = "1"
        round_trip_time_ms =  "20"
    }
  }

  test_group {
    name                     = "example-test-group"
    destination_endpoints    = ["destination"]
    source_endpoints         = ["source"]
    test_configuration_names = ["http-test"]
  }

  notes = "examplenote"

  output_workspace_resource_ids = [data.azurerm_log_analytics_workspace.example.id]
  
}