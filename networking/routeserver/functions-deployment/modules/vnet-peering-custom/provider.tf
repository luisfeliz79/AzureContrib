terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.51.0"
    }
    azapi = {
      source ="Azure/azapi"
      version = ">= 1.3.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  subscription_id = var.left_subscription_id

  storage_use_azuread = true

  features {
 
  }
  
}

provider "azurerm" {
  alias = "right"
  subscription_id = var.right_subscription_id

  features {
  }
}
