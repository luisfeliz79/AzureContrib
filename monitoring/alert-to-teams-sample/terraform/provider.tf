terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.49.0"
    }
  }
}

provider "azurerm" {

  subscription_id = local.subscription_id
  
  features {
    storage {
      data_plane_available = false
    }

    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}