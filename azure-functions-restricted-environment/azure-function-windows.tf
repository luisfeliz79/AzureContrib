# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_function_app

resource "azurerm_service_plan" "plan1" {
  name                = "${local.rg_prefix}-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "P1v3"

}

resource "azurerm_windows_function_app" "funcapp" {
  name                       = "${local.rg_prefix}-funcwin"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  storage_account_name       = azurerm_storage_account.sa.name
  service_plan_id            = azurerm_service_plan.plan1.id
  storage_uses_managed_identity = true

  identity {
    type = "SystemAssigned"
  }

  # This is for Outbound traffic
  # Incoming traffic is handled by Private endpoints
  virtual_network_subnet_id = azurerm_subnet.functions_subnet.id

  https_only = true
 

  site_config {

    application_insights_connection_string = azurerm_application_insights.ai.connection_string
    application_insights_key = azurerm_application_insights.ai.instrumentation_key
    always_on = true

    cors {
      allowed_origins = ["https://portal.azure.com"]
    }

    # If accessing the Azure Portal from a machine
    # that can route directly over private endpoints
    # then completely disable public network access
    # using the line below:
    # public_network_access_enabled = false

    # If accessing over a proxy, use IP restrictions instead
    # and specify the Ip addresses instead
    # using the ip_address directive below
    ip_restriction {
        action      = "Allow"
        ip_address  = local.user_ip_address_cidr
        name        = "UserIP"
        priority    = 300
    }

    # Linting may complain about the lines below
    # Ignore the linting errors, it works
    scm_ip_restriction_default_action = "Deny"
    ip_restriction_default_action = "Deny"
    
    
    scm_use_main_ip_restriction = true

    application_stack {
      powershell_core_version = 7.2
    }
  }

  app_settings = {

    # This is just a sample variable, it will surface on functions
    # as an environment variable
    "VAULT_NAME" = azurerm_key_vault.support_kv.name

    # This is how we handle Authentication to Storage using Entra ID
    # REF: https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference?tabs=blob&pivots=programming-language-powershell#connecting-to-host-storage-with-an-identity:~:text=To%20use%20an%20identity%2Dbased%20connection%20for%20AzureWebJobsStorage%2C%20configure%20the%20following%20app%20settings%3A
    "AzureWebJobsStorage__blobServiceUri"="https://${azurerm_storage_account.sa.name}.blob.core.windows.net"
    "AzureWebJobsStorage__queueServiceUri"="https://${azurerm_storage_account.sa.name}.queue.core.windows.net"
    "AzureWebJobsStorage__tableServiceUri"="https://${azurerm_storage_account.sa.name}.table.core.windows.net"

    # This is how we handle Authentication to Event Hubs using Entra ID
    # REF: https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-hubs-trigger?tabs=python-v2%2Cisolated-process%2Cnodejs-v4%2Cfunctionsv2%2Cextensionv5&pivots=programming-language-powershell#identity-based-connections
    "EVENTHUB__fullyQualifiedNamespace"="${azurerm_eventhub_namespace.ehns.name}.servicebus.windows.net"

    # This is how we can do Key Vault references to source secrets directly from KV into Environment variables
    # REF: https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references?toc=%2Fazure%2Fazure-functions%2Ftoc.json&tabs=azure-cli#source-app-settings-from-key-vault
    "KeyVaultRefSample" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.support_kv.name};SecretName=${azurerm_key_vault_secret.mysecrets.name})"

  }

  # Azure Functions populates some tags directly that
  # could conflict with terraform, ignore the tags
  lifecycle {
    ignore_changes = [ tags ]
  }

}

