# RBAC Assignments - UAMI to Storage account - ROle - Storage Blob Data Contributor

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment
resource "azurerm_role_assignment" "uami_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.log_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.automation_identity.principal_id
}

# RBAC Assignments - UAMI to Key Vault - Role - Key Vault Secrets User
resource "azurerm_role_assignment" "uami_key_vault_secrets_user" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_user_assigned_identity.automation_identity.principal_id  
}  

# RBAC Assignments - Contributor role to the Automation account
# Needed for Source Control configuratoin
resource "azurerm_role_assignment" "uami_automation_contributor" {
  scope                = azurerm_automation_account.automation_account.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.automation_identity.principal_id  
}  
