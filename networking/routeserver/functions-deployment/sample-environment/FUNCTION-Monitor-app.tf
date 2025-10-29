resource "azurerm_log_analytics_workspace" "law" {
  name                = local.support_loganalytics_name
  location            = azurerm_resource_group.azuregw.location 
  resource_group_name = azurerm_resource_group.azuregw.name
  sku                 = "PerGB2018"

  tags = local.tags
}

resource "azurerm_application_insights" "ai" {
  name                = local.support_appinsights_name
  location            = azurerm_resource_group.azuregw.location 
  resource_group_name = azurerm_resource_group.azuregw.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"

  local_authentication_disabled = false
  # Azure Functions does not support Entra ID auth to App Insights as of 4/2/2024
  # https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-ad-authentication?tabs=net#unsupported-scenarios

}

resource "azurerm_storage_account" "sa" {
  name                       = local.support_storageaccount_name
  location                   = azurerm_resource_group.azuregw.location
  resource_group_name        = azurerm_resource_group.azuregw.name

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  https_traffic_only_enabled = true
  min_tls_version           = "TLS1_2"

  shared_access_key_enabled = false

  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action = "Deny"
    ip_rules = [local.user_ip_address]    
  }

  lifecycle {
    ignore_changes = [ customer_managed_key, network_rules ]
  }


  tags = local.tags
}


# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_function_app

resource "azurerm_service_plan" "plan1" {
  name                = "molabs-monitor-plan"
  resource_group_name = azurerm_resource_group.azuregw.name
  location            = azurerm_resource_group.azuregw.location
  os_type             = "Linux"
  sku_name            = "P1v3"

}

resource "azurerm_linux_function_app" "funcapp" {
  name                       = "molabs-funcapp"
  resource_group_name        = azurerm_resource_group.azuregw.name
  location                   = azurerm_resource_group.azuregw.location
  storage_account_name       = azurerm_storage_account.sa.name
  service_plan_id            = azurerm_service_plan.plan1.id
  
  //vnet integration
  virtual_network_subnet_id = azurerm_subnet.azuregw-appsvc.id
  

  //Security  
  ftp_publish_basic_authentication_enabled = false
  webdeploy_publish_basic_authentication_enabled = false
  storage_uses_managed_identity = true
  https_only = true


  identity {
    type = "SystemAssigned"
  }

  tags = {
    "hidden-link: /app-insights-resource-id" = azurerm_application_insights.ai.id
  }

  site_config {

    application_insights_connection_string = azurerm_application_insights.ai.connection_string
    #application_insights_key = azurerm_application_insights.ai.instrumentation_key
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
        ip_address  = "${local.user_ip_address}/32"
        name        = "UserIP"
        priority    = 300
    }

    # Linting may complain about the lines below
    # Ignore the linting errors, it works
    scm_ip_restriction_default_action = "Deny"
    ip_restriction_default_action     = "Deny"
    vnet_route_all_enabled            = true
    
    
    scm_use_main_ip_restriction = true

    application_stack {
      powershell_core_version = 7.4
    }
  }

  app_settings = {

    MONITOR_ENDPOINT_URI      = module.customlog.DCE_INGEST_FQDN
    MONITOR_DCR_IMMUTABLE_ID  = module.customlog.DCR_IMMUTABLE_ID
    ROUTE_SERVER_ID           = local.include_route_server ? module.route-server[0].id : ""
    ERGW_ID                   = local.include_vnetgw ? module.vpngateway[0].gateway_id: ""

    #APPLICATIONINSIGHTS_AUTHENTICATION_STRING = "Authorization=AAD"
    AzureWebJobsStorage__blobServiceUri       = azurerm_storage_account.sa.primary_blob_endpoint
    AzureWebJobsStorage__queueServiceUri      = azurerm_storage_account.sa.primary_queue_endpoint
    AzureWebJobsStorage__tableServiceUri      = azurerm_storage_account.sa.primary_table_endpoint
    AzureWebJobsStorage__credential           = "managedidentity"

    # This is just a sample variable, it will surface on functions
    # as an environment variable
    #"VAULT_NAME" = azurerm_key_vault.support_kv.name

    # This is how we handle Authentication to Storage using Entra ID
    # REF: https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference?tabs=blob&pivots=programming-language-powershell#connecting-to-host-storage-with-an-identity:~:text=To%20use%20an%20identity%2Dbased%20connection%20for%20AzureWebJobsStorage%2C%20configure%20the%20following%20app%20settings%3A
    #"AzureWebJobsStorage__blobServiceUri"="https://${azurerm_storage_account.sa.name}.blob.core.windows.net"
    #"AzureWebJobsStorage__queueServiceUri"="https://${azurerm_storage_account.sa.name}.queue.core.windows.net"
    #"AzureWebJobsStorage__tableServiceUri"="https://${azurerm_storage_account.sa.name}.table.core.windows.net"

    # This is how we handle Authentication to Event Hubs using Entra ID
    # REF: https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-hubs-trigger?tabs=python-v2%2Cisolated-process%2Cnodejs-v4%2Cfunctionsv2%2Cextensionv5&pivots=programming-language-powershell#identity-based-connections
    #"EVENTHUB__fullyQualifiedNamespace"="${azurerm_eventhub_namespace.ehns.name}.servicebus.windows.net"

    # This is how we can do Key Vault references to source secrets directly from KV into Environment variables
    # REF: https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references?toc=%2Fazure%2Fazure-functions%2Ftoc.json&tabs=azure-cli#source-app-settings-from-key-vault
    #"KeyVaultRefSample" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.support_kv.name};SecretName=${azurerm_key_vault_secret.mysecrets.name})"

  }

  # Azure Functions populates some tags directly that
  # could conflict with terraform, ignore the tags
  lifecycle {
    ignore_changes = [ tags ]
  }

  

}

# Configure RBAC for the storage account
resource "azurerm_role_assignment" "sa_funcapp" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.funcapp.identity[0].principal_id

  depends_on = [ azurerm_linux_function_app.funcapp ]

}

# # Configure RBAC for the Storage account files
# resource "azurerm_role_assignment" "sa_funcapp_files" {
#   scope                = azurerm_storage_account.sa.id
#   role_definition_name = "Storage File Data Contributor"
#   principal_id         = azurerm_linux_function_app.funcapp.identity[0].principal_id
# }

# Configure RBAC for Route Server Contributor role for the function app
resource "azurerm_role_assignment" "funcapp_route_server_contributor" {

  count = local.include_route_server ? 1 : 0

  scope                = module.route-server[0].id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_function_app.funcapp.identity[0].principal_id

  depends_on = [ azurerm_linux_function_app.funcapp ]
}

# Configure RBAC for the data collection rule
resource "azurerm_role_assignment" "funcapp_data_collection_rule" {

  count = local.include_route_server ? 1 : 0

  scope                = module.customlog.DCR_RESOURCE_ID
  role_definition_name = "Monitoring metrics publisher"
  principal_id         = azurerm_linux_function_app.funcapp.identity[0].principal_id

  depends_on = [ azurerm_linux_function_app.funcapp ]
}


output "publish_code_command" {
  value = "az webapp deployment source config-zip --resource-group ${azurerm_linux_function_app.funcapp.resource_group_name} --name ${azurerm_linux_function_app.funcapp.name} --src '../routes-functions.zip'"
}