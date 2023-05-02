# Azure provider version 
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      #version = "= 3.32.0"
    }

  }
}

provider "azurerm" {
    features {} 
}


# Resource group
resource "azurerm_resource_group" "spoke_rg" {
    name                        = "testairg"
    location                    = "eastus"

}

# Log Analytics workspace - this is the storage for App Insights
resource "azurerm_log_analytics_workspace" "law" {
  name                = "testailaw999"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# App Insights resource tied to the Log Analytics workspace
resource "azurerm_application_insights" "app_insights" {
  name                = "testappinsights999"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "java"
}



# Storage account is for the demoapp only, and not required for Application Insights
resource "azurerm_storage_account" "storage_account" {
  name                     = "testdemosa999"
  location                 = azurerm_resource_group.spoke_rg.location
  resource_group_name      = azurerm_resource_group.spoke_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}