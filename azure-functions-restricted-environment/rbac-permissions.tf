# Deploy permissions for the Storage account for Azure Functions Managed Identity
resource "azurerm_role_assignment" "func-blob-rbac" {  
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_windows_function_app.funcapp.identity[0].principal_id
}

# Deploy permissions for the Storage account for Azure Functions Managed Identity
resource "azurerm_role_assignment" "func-queue-rbac" {  
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_windows_function_app.funcapp.identity[0].principal_id
}

# Deploy permissions for the Storage account for Azure Functions Managed Identity
resource "azurerm_role_assignment" "func-sa-mgmt-rbac" {  
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_windows_function_app.funcapp.identity[0].principal_id
}

# Deploy permissions for the Key Vault for Azure Functions Managed Identity
resource "azurerm_role_assignment" "func-kv-mgmt-rbac" {  
  scope                = azurerm_key_vault.support_kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_function_app.funcapp.identity[0].principal_id
}

# Deploy permissions for the Key Vault for Azure Functions Managed Identity
resource "azurerm_role_assignment" "sa-kv-rbac" {  
  scope                = azurerm_key_vault.support_kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_storage_account.sa.identity[0].principal_id

  depends_on = [ azurerm_storage_account.sa ]

}

# Deploy permissions for the Event Hub for Azure Functions Managed Identity
resource "azurerm_role_assignment" "func-eventhub-rbac" {  
  scope                = azurerm_eventhub_namespace.ehns.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_windows_function_app.funcapp.identity[0].principal_id
}






