terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 4.22.0"
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
    user_ip_address = "x.x.x.x"
    
}

# define a resource group
resource "azurerm_resource_group" "rg0" {
    name     = "azure-monitor-rg"
    location = local.region0
}

# info about the currently logged in user
data "azurerm_client_config" "current" {}