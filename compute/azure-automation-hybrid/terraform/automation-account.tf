
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


# Create a variable to store the client ID of the UAMI
# as part of the Source control configuraton
resource "azurerm_automation_variable_string" "uami_client_id" {
  name                    = "AUTOMATION_SC_USER_ASSIGNED_IDENTITY_ID"
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.automation_account.name
  value                   = azurerm_user_assigned_identity.automation_identity.client_id
}

# Configure source control
resource "azurerm_automation_source_control" "github" {
  name                    = "ghes-source-control"
  automation_account_id   = azurerm_automation_account.automation_account.id
  folder_path = "/runbooks"

  source_control_type = "GitHub"
  branch              = "main"
  repository_url    = "https://github.com/<account>/<repo>.git"


  description = "Sync runbooks from GitHub Enterprise Server repository"

  security {
    token_type = "PersonalAccessToken" #or Oauth
    token      = ""  # Only if PersonalAccessToken is used. If Oauth is used, this field should be left empty.
  }


  # Automatically sync changes from the repo to the Automation Account
  automatic_sync = true
}




