resource "azurerm_storage_account" "sa" {
  name                       = local.support_storageaccount_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "ZRS"
  https_traffic_only_enabled = true
  min_tls_version           = "TLS1_2"

  allow_nested_items_to_be_public = false

  # Logic apps standard requires this to be true
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
    ignore_changes = [ customer_managed_key, network_rules,tags ]
  }

  


  tags = local.tags
}