
resource "azurerm_key_vault" "support_kv" {
  name                       = local.support_keyvault_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  enable_rbac_authorization  = true
  purge_protection_enabled = true
  
  network_acls {
    default_action = "Deny"
    bypass = "AzureServices"
    ip_rules = [local.user_ip_address]
  }
 
  tags = local.tags
  
}

# Used for testing functions reading a secret
resource "azurerm_key_vault_secret" "mysecrets" {
  name         = "Test"
  value        = "This is my secret text!"
  key_vault_id = azurerm_key_vault.support_kv.id

  depends_on = [ azurerm_role_assignment.deploy-kv-user-rbac ]
}

# Used for Storage account CMK
resource "azurerm_key_vault_key" "sacmk" {
  name         = "cmk"
  key_vault_id = azurerm_key_vault.support_kv.id
  key_size     = 2048
  key_type     = "RSA"
  key_opts     = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey"
  ]
  depends_on = [ azurerm_role_assignment.deploy-kv-user-rbac ]
}

