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
  subscription_id = local.subscription_id

  storage_use_azuread = true

  features {
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true
      recover_soft_deleted_secrets          = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
  }
  
}
