resource "azurerm_storage_account" "sa" {
  name                       = local.support_storageaccount_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true

  shared_access_key_enabled = false

  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action = "Deny"
    ip_rules = [local.user_ip_address]    
  }

  lifecycle {
    ignore_changes = [ customer_managed_key ]
  }


  tags = local.tags
}

# Customer Managed Key setup
resource "azurerm_storage_account_customer_managed_key" "cmk" {
  storage_account_id = azurerm_storage_account.sa.id
  key_vault_id       = azurerm_key_vault.support_kv.id
  key_name           = azurerm_key_vault_key.sacmk.name

  depends_on = [ azurerm_role_assignment.sa-kv-rbac ]
}