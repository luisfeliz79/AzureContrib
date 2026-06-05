# Azure KeyVault
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault
resource "azurerm_key_vault" "key_vault" {
  name                        = local.key_vault_name
  resource_group_name         = local.resource_group_name
  location                    = local.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  rbac_authorization_enabled  = true
  soft_delete_retention_days  = 90

  public_network_access_enabled = true
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [local.egress_ip_address]            
  }
    
}

# Key Vault Key for Storage account CMK
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key
resource "azurerm_key_vault_key" "storage_account_key" {
  name         = "storage-account-key"
  key_vault_id = azurerm_key_vault.key_vault.id
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
}

# Sample Key Vault Secret
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret
resource "azurerm_key_vault_secret" "sample_secret" {
  name         = "sample-secret"
  value        = "sample-value"
  key_vault_id = azurerm_key_vault.key_vault.id
}

# Sample Key Vault Certificate
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate
resource "azurerm_key_vault_certificate" "sample_certificate" {
  name         = "sample-certificate"
  key_vault_id = azurerm_key_vault.key_vault.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      subject            = "CN=sample-certificate"
      validity_in_months = 12
      key_usage          = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyEncipherment",
        "nonRepudiation"
      ]
    }
  }
}
