locals {
  # resource_group_name         = "teams-alert-on-ase-rg"
  # logic_app_name              = "teams-alert-on-ase"
  # location                    = "eastus2"
  # support_storageaccount_name = "lufelizlogap333"
  # user_ip_address             = "162.226.7.217"
  # support_loganalytics_name   = "lufelizlaw333"
  # support_appinsights_name    = "lufelizappinsights333"
  # support_keyvault_name       = "lufelizkv333"
  # uami_name                   = "logicapp-uami333"
  # subscription_id             = "f0df4358-9e4c-43aa-82ec-eebde4fd8233"

  # tags = {
  #   Environment = "Development"
  #   Project     = "Teams Notifications Logic App"
  # }

  resource_group_name         = "alert-to-teams-rg"
  logic_app_name              = "alert-to-teams-logic-app"
  location                    = "eastus2"
  support_storageaccount_name = "<storage_account_name>"
  user_ip_address             = "<your_egress_ip_address>"
  support_loganalytics_name   = "<log_analytics_workspace_name>"
  support_appinsights_name    = "<application_insights_name>"
  uami_name                   = "logicapp-uami"
  subscription_id             = "<your_subscription_id>"

  tags = {
    Environment = "Development"
    Project     = "Alert to Teams Logic App Sample"
  }
}


resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
  tags = local.tags
}

data "azurerm_client_config" "current" {}

