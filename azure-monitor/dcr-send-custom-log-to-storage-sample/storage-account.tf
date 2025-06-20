resource "azurerm_storage_account" "sa1" {
  name                       = "luisazmonsa1"
  location                   = azurerm_resource_group.rg0.location
  resource_group_name        = azurerm_resource_group.rg0.name

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  https_traffic_only_enabled = true

  shared_access_key_enabled = false

  public_network_access_enabled = false


  network_rules {
    default_action = "Deny"
    ip_rules = [local.user_ip_address]    
  }

}

# create a container in the storage account
resource "azurerm_storage_container" "container1" {
  name                  = "azure-monitor"
  storage_account_id  = azurerm_storage_account.sa1.id
  container_access_type = "private"
}
