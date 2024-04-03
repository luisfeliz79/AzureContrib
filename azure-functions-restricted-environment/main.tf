# Azure provider version 
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.32.0"
    }
    random = {
      source = "hashicorp/random"
      version = "= 3.4.3"
    }
  }
}

provider "azurerm" {
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


locals  {
  rg_prefix                = "restricted"
  location                 = "westus"

  vnet_prefix              = "10.0.0.0/16"
  functions_subnet         = "10.0.1.0/24"
  endpoints_subnet         = "10.0.2.0/24"

  support_keyvault_name         = "k${random_string.suffix.result}-hub-kv"
  support_storageaccount_name   = "sa${random_string.suffix.result}${local.location}"
  support_loganalytics_name     = "law${random_string.suffix.result}${local.location}"
  support_appinsights_name      = "ai${random_string.suffix.result}${local.location}"
  support_eventhub_name         = "eh${random_string.suffix.result}${local.location}"

  # Specify an IP address here if accessing the deployed resources publically
  # in a customer environment, management is likely happening using a jumpbox
  user_ip_address_cidr = "x.x.x.x/32"
  user_ip_address      = "x.x.x.x"

  tags = { 
    experiment = local.rg_prefix  
  }
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length = 5
  upper = false
  special = false
}

resource "random_password" "sharedsecret" {
  length = 15
  upper = true
  special = true  
}


resource "azurerm_resource_group" "rg" {
    name                        = "${local.rg_prefix}-secfunc-rg"
    location                    = local.location

    tags = local.tags
}

