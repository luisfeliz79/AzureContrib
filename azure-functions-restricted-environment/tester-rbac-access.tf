# These are items that help the user get
# access to the deployed resources
# for learning purposes.  This access is not required.
# for normal operation of Azure functions

# Give Storage account permission to logged in user (so that it can upload to the SA)
resource "azurerm_role_assignment" "deploy-blob-user-rbac" {  
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Give Key Vault permissions to the logged in user (so that it can review data )
resource "azurerm_role_assignment" "deploy-kv-user-rbac" {  
  scope                = azurerm_key_vault.support_kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id

}


