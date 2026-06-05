terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  subscription_id = local.subscription_id
  
  storage_use_azuread = true

  features {
    storage {
      data_plane_available = true
    }    
  }
}

provider "azapi" {}
