# RBAC Assignments required by Logic apps
resource "azurerm_role_assignment" "ra-monitoring-metrics-publisher" {
  scope                = azurerm_application_insights.ai.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_user_assigned_identity.uami.principal_id
}

resource "azurerm_role_assignment" "ra-storage-table-data-contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_user_assigned_identity.uami.principal_id
}

resource "azurerm_role_assignment" "ra-storage-queue-data-contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.uami.principal_id
}

resource "azurerm_role_assignment" "ra-storage-account-contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.uami.principal_id
}

resource "azurerm_role_assignment" "ra-storage-blob-data-owner" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.uami.principal_id
}


