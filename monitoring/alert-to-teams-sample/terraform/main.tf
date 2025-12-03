locals {
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

