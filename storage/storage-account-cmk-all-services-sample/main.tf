terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
 
  storage_use_azuread = true

  features {
    
    key_vault {
      purge_soft_delete_on_destroy = true
    }

    storage {
      
    }
  }
  subscription_id = local.subscription_id
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}

# --- Key Vault ---

resource "azurerm_key_vault" "kv" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  rbac_authorization_enabled = true
}

# --- Key Vault Key for CMK ---

resource "azurerm_key_vault_key" "cmk" {
  name         = "storage-cmk-key"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  depends_on = [azurerm_role_assignment.deployer_kv_crypto_officer]
}

# --- Storage Account ---

resource "azurerm_storage_account" "sa" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # ------------------------------------------------------------------------
  # Sample to enable CMK encryption on all services (Blob, Queue, Table) ---
  # While ignoring existing storage accounts settings
  # To prevent storage account recreation, we use lifecycle block to ignore changes to the following properties:
  # - infrastructure_encryption_enabled
  # - queue_encryption_key_type
  # - table_encryption_key_type
  # - customer_managed_key
  # In addition, we set prevent_destroy to true to prevent accidental deletion of the storage account.
  #
  # Warning: Test thoroughly before using this in production
  #          To validate any environmental differences with Lab testing
  # -----------------------------------------------------------------------

  infrastructure_encryption_enabled = true 
  queue_encryption_key_type = "Account"
  table_encryption_key_type = "Account"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [
      infrastructure_encryption_enabled,
      queue_encryption_key_type,
      table_encryption_key_type,
      customer_managed_key
      ]
  }

  identity {
    type = "SystemAssigned"
  }
}

# --- CMK Encryption on Storage Account ---

resource "azurerm_storage_account_customer_managed_key" "cmk" {
  storage_account_id = azurerm_storage_account.sa.id
  key_vault_key_id   = azurerm_key_vault_key.cmk.id

  depends_on = [azurerm_role_assignment.storage_to_kv]
}



# --- RBAC: Storage Account -> Key Vault (for CMK) ---

resource "azurerm_role_assignment" "storage_to_kv" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_storage_account.sa.identity[0].principal_id
}

