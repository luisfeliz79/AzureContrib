output "storage_account_id" {
  value = azurerm_storage_account.sa.id
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "key_vault_key_id" {
  value = azurerm_key_vault_key.cmk.id
}

output "container_name" {
  value = azurerm_storage_container.container.name
}
