terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 4.22.0"
    }

    azapi = {
      source = "Azure/azapi"
      version = "2.3.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-bebeff55a41d"

  storage_use_azuread = true
  
  features {    
  }
}

locals {
    region0="eastus2"
    
    
}

# define a resource group
resource "azurerm_resource_group" "rg0" {
    name     = "azure-monitor3-rg"
    location = local.region0
}

# info about the currently logged in user
data "azurerm_client_config" "current" {}

# Existing LAW
data "azurerm_log_analytics_workspace" "law" {
  name                = "xxxxxx"
  resource_group_name = "azure-monitor2-rg"
}

# Existing DCE
data "azurerm_monitor_data_collection_endpoint" "region0dce" {
  name                = "dce-eastus2"
  resource_group_name = "azure-monitor2-rg"
}


