terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.47.0"
    }
  }
}

provider "azurerm" {
  subscription_id = local.subscription_id
  features {}
}
