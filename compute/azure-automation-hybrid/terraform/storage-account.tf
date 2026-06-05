# Storage Account
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
resource "azurerm_storage_account" "log_storage_account" {
  name                     = local.storage_account_name
  resource_group_name      = local.resource_group_name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  
  allow_nested_items_to_be_public = false
  shared_access_key_enabled = false

  identity {
      type = "SystemAssigned"
  }

  public_network_access_enabled = true
  network_rules {
    default_action = "Deny"
    bypass = ["AzureServices"]
    ip_rules       = [local.egress_ip_address]
  }

}