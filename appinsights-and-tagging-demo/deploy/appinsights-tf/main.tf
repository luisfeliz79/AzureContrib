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

# Log Analytics workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "mstestailaw"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# App Insights resource tied to the Log Analytics workspace
resource "azurerm_application_insights" "app_insights" {
  name                = "mstestappinsights"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "java"
}
