# Deploy permissions for the Storage account for the currently logged in user
# To be able to explore the container
resource "azurerm_role_assignment" "func-sa-mgmt-rbac" {  
  scope                = azurerm_storage_account.sa1.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
