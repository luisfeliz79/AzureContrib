
# Automation Account
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_account
resource "azurerm_automation_account" "automation_account" {
  name                = local.automation_account_name
  resource_group_name = local.resource_group_name
  location            = local.location
  sku_name            = "Basic"

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.automation_identity.id
    ]
  }
  tags                = local.tags
}



# Sample String Variable
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string
resource "azurerm_automation_variable_string" "example" {
  name                    = "tfex-example-var"
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  value                   = "Hello, Terraform Basic Test."
}

# Sample Automation account credentials
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_credential
resource "azurerm_automation_credential" "sample_credential" {
  name                    = "sample-credential"
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  username                = "sample-username"
  password                = "sample-password"
}

# Worker Group
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_hybrid_runbook_worker_group
resource "azurerm_automation_hybrid_runbook_worker_group" "worker_group" {
  name                    = "hybrid-worker-group"
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  
}




