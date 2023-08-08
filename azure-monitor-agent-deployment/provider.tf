terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.51.0"
    }
    azapi = {
      source ="Azure/azapi"
      version = "1.3.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
  
}