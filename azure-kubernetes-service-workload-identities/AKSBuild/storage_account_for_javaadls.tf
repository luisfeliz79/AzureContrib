resource "azurerm_storage_account" "sa" {
  name                     = "${local.cluster_name}storage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  is_hns_enabled = true
  nfsv3_enabled = true

  network_rules {
    default_action = "Deny"
    # This is to allow network access from the Cluster to the storage account
    virtual_network_subnet_ids = [azurerm_subnet.spoke_akscni.id]  
  }

}


# This is for the Managed Identity to read/write data from a Pod
resource "azurerm_role_assignment" "sablobread" {
  scope                 = azurerm_storage_account.sa.id
  role_definition_name  = "Storage Blob Data Contributor"
  principal_id          = azurerm_user_assigned_identity.uaid1.principal_id
}

# This is for allowing the cluster to mount NFSv3 shares
resource "azurerm_role_assignment" "sablobread2" {
  scope                 = azurerm_storage_account.sa.id
  role_definition_name  = "Storage Blob Data Contributor"
  principal_id          = azurerm_kubernetes_cluster.aksapp.identity[0].principal_id
}

output _storage_account_name {
  value = azurerm_storage_account.sa.name
}
