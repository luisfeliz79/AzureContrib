terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.83.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }

    azapi = {
      source ="Azure/azapi"
      version = ">= 1.3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  storage_use_azuread = true
  skip_provider_registration = true
}

locals {
  func_name = "privsa2${random_string.unique.result}"
  loc_for_naming = "eastus"
  sa_name = "${local.func_name}${local.loc_for_naming}sa"
  tags = {
    "managed_by" = "terraform"
    "repo"       = "terraform-samples"
  }
}

# Specify already created Resources
# User assigned managed identity
data "azurerm_user_assigned_identity" "uaid1" {
  name                = "test-uaid1"
  resource_group_name = "rg-test-uaid1"
}

# A Key vault instance
# Configure Soft delete and RBAC permission model
# Configure the UAMI to have the "Key Vault Crypto User" role
# Configure Firewall -> Allow trusted Microsoft services

# Configure either Private endpoints or Firewall -> Your client IP of where terraform is running
data "azurerm_key_vault" "kv" {
  name                = "test-kv"
  resource_group_name = "test-kv-rg"
}

# A Key vault Key - named "cmk" or your choice
data "azurerm_key_vault_key" "cmk" {
  name         = "cmk"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_client_config" "current" {}

# Start deployments

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.func_name}-${local.loc_for_naming}"
  location = local.loc_for_naming
}

resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}



resource "azurerm_virtual_network" "default" {
  name                = "vnet-${local.func_name}-${local.loc_for_naming}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.4.0.0/24"]

  tags = local.tags
}

resource "azurerm_subnet" "pe" {
  name                  = "snet-privateendpoints-${local.loc_for_naming}"
  resource_group_name   = azurerm_virtual_network.default.resource_group_name
  virtual_network_name  = azurerm_virtual_network.default.name
  address_prefixes      = ["10.4.0.0/26"]

  private_endpoint_network_policies_enabled = true

}

resource "azurerm_subnet" "vms" {
  name                  = "snet-vms-${local.loc_for_naming}"
  resource_group_name   = azurerm_virtual_network.default.resource_group_name
  virtual_network_name  = azurerm_virtual_network.default.name
  address_prefixes      = ["10.4.0.128/26"]
 
}

resource "azurerm_private_dns_zone" "blob" {
  name                      = "privatelink.blob.core.windows.net"
  resource_group_name       = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "file" {
  name                      = "privatelink.file.core.windows.net"
  resource_group_name       = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "queue" {
  name                      = "privatelink.queue.core.windows.net"
  resource_group_name       = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "table" {
  name                      = "privatelink.table.core.windows.net"
  resource_group_name       = azurerm_resource_group.rg.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.default.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  name                  = "file"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = azurerm_virtual_network.default.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue" {
  name                  = "queue"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.default.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "table"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.default.id
}

resource "azurerm_private_endpoint" "peblob" {
  name                = "pe-blob-sa${local.func_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe.id

  private_service_connection {
    name                           = "pe-connection-blob-sa${local.func_name}"
    private_connection_resource_id = azapi_resource.azapi_sa.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.blob.name
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

resource "azurerm_private_endpoint" "pefile" {
  name                = "pe-file-sa${local.func_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe.id

  private_service_connection {
    name                           = "pe-connection-file-sa${local.func_name}"
    private_connection_resource_id = azapi_resource.azapi_sa.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.file.name
    private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
  }
}

resource "azurerm_private_endpoint" "petable" {
  name                = "pe-table-sa${local.func_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe.id

  private_service_connection {
    name                           = "pe-connection-table-sa${local.func_name}"
    private_connection_resource_id = azapi_resource.azapi_sa.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }
  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.table.name
    private_dns_zone_ids = [azurerm_private_dns_zone.table.id]
  }
}

resource "azurerm_private_endpoint" "pequeue" {
  name                = "pe-queue-sa${local.func_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe.id

  private_service_connection {
    name                           = "pe-connection-queue-sa${local.func_name}"
    private_connection_resource_id = azapi_resource.azapi_sa.id
    is_manual_connection           = false
    subresource_names              = ["queue"]
  }
  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.queue.name
    private_dns_zone_ids = [azurerm_private_dns_zone.queue.id]
  }
}



resource "azapi_resource" "azapi_sa" {
  type = "Microsoft.Storage/storageAccounts@2022-09-01"
  name = local.sa_name
  location = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
  tags = local.tags

  identity {
   type = "UserAssigned"
   identity_ids = [data.azurerm_user_assigned_identity.uaid1.id]
  }
  body = jsonencode({
    sku = {
      name = "Standard_LRS"
    }
    kind = "StorageV2"
    properties = {
      accessTier = "Hot"
      allowBlobPublicAccess = false
      allowCrossTenantReplication = false
      allowSharedKeyAccess = false
      defaultToOAuthAuthentication = true
      isNfsV3Enabled = false
      supportsHttpsTrafficOnly = true
      minimumTlsVersion = "TLS1_2"
      publicNetworkAccess = "Disabled"
  
      
      networkAcls = {
        bypass = "Logging, Metrics, AzureServices"
        defaultAction = "Deny"
      }


      encryption = {
        identity = {
          userAssignedIdentity = data.azurerm_user_assigned_identity.uaid1.id
        }

        keySource = "Microsoft.Keyvault"

        keyvaultproperties = {
          keyname = data.azurerm_key_vault_key.cmk.name
          keyvaulturi = data.azurerm_key_vault.kv.vault_uri
          keyversion = ""
        }

        services = {
          blob = {
            enabled = true
            keyType = "Account"
          }
          file = {
            enabled = true
            keyType = "Account"
          }
        }
        
        
      }
      


    }


  })
}


# For reference - old resource



# resource "azurerm_storage_account" "sa" {
#   name                     = "saprivsa2cnp9tzt1"
#   resource_group_name      = azurerm_resource_group.rg.name
#   location                 = azurerm_resource_group.rg.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"

#   public_network_access_enabled   = false

#   min_tls_version = "TLS1_2"
#   enable_https_traffic_only = true
#   nfsv3_enabled = false

#   allow_nested_items_to_be_public = false

#   # queue_encryption_key_type = "Service"
#   # table_encryption_key_type = "Service"
  
#   # infrastructure_encryption_enabled = true
#   # shared_access_key_enabled = false 

#   # identity {
#   #   type = "UserAssigned"
#   #   identity_ids = [data.azurerm_user_assigned_identity.uaid1.id]
#   # }

#   # network_rules {
#   #   default_action = "Deny"
#   #   #ip_rules = [""]
#   #   bypass = ["Logging", "Metrics", "AzureServices"]
#   #   virtual_network_subnet_ids = []
#   # }

#   # blob_properties {
#   #   dynamic "delete_retention_policy" {
#   #     for_each = [1]
#   #     content {
#   #       days    = 7
#   #     }
      
#   #   }
#   # }

#   # dynamic "static_website" {
#   #   for_each = [1]
#   #   content {
#   #     index_document = "index.html"
#   #     error_404_document = "404.html"
#   #   }
    
#   # }

#   # customer_managed_key {
#   #   key_vault_key_id = data.azurerm_key_vault_key.cmk.versionless_id
#   #   user_assigned_identity_id = data.azurerm_user_assigned_identity.uaid1.id

#   # }

#   tags = local.tags
# }