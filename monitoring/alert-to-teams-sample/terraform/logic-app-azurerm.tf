
resource "azurerm_logic_app_standard" "logicapp" {
  name                = local.logic_app_name 
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_service_plan.plan.id

  #virtual_network_subnet_id  = azurerm_subnet.logic-apps.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  public_network_access      = "Enabled"
  vnet_content_share_enabled = true
  client_affinity_enabled    = false
  https_only                 = true
  ftp_publish_basic_authentication_enabled = false
  scm_publish_basic_authentication_enabled = false
  

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uami.id]
  }




  site_config {

    always_on = true

    # This configures outbound access to flow out via VNET
    # This means teams endpoints should be allowed on the Firewall    
    vnet_route_all_enabled = true
    
    # Minimum TLS version settings
    scm_min_tls_version = "1.2"
    min_tls_version = "1.2"
    
    # Note:
    # azurerm_logic_app_standard will default deny for
    # ip restriction default action and scm ip restriction default action
    # However, avoid AzureRM 3.95 due to issues with these settings


    # This is required to allow Action Groups to connect    
    ip_restriction {
      service_tag = "ActionGroup"
      action      = "Allow"
      name        = "Allow-ActionGroups"
      description = "Traffic from Azure Monitor Action Groups"

    }

    # This should be the deployment machine IP
    ip_restriction {
      ip_address = "${local.user_ip_address}/32"
      action     = "Allow"
      name       = "Allow-Testing-Machine"
      description = "Optional rule to allow for testing from specific IP"
    }

    scm_ip_restriction {
      ip_address = "${local.user_ip_address}/32"
      action     = "Allow"
      name       = "Allow-Deployment-Machine"
      description = "Allows for deployment of the logic app code from specific IP"
    }


  }

  app_settings = {

    TEAMS_API_RUNTIME_URL          = jsondecode(azurerm_resource_group_template_deployment.teams-api-connection.output_content).connectionRuntimeUrl.value
    WORKFLOWS_SUBSCRIPTION_ID      = data.azurerm_client_config.current.subscription_id
    WORKFLOWS_RESOURCE_GROUP_NAME  = azurerm_resource_group.rg.name
    WORKFLOWS_LOCATION_NAME        = azurerm_resource_group.rg.location

    FUNCTIONS_WORKER_RUNTIME     = "dotnet"
    WEBSITE_NODE_DEFAULT_VERSION = "~25"

    APPLICATIONINSIGHTS_CONNECTION_STRING     = azurerm_application_insights.ai.connection_string
    APPLICATIONINSIGHTS_AUTHENTICATION_STRING = "ClientId=${azurerm_user_assigned_identity.uami.client_id};Authorization=AAD"

    AzureWebJobsStorage__credential                = "managedidentity"
    AzureWebJobsStorage__blobServiceUri            = azurerm_storage_account.sa.primary_blob_endpoint
    AzureWebJobsStorage__queueServiceUri           = azurerm_storage_account.sa.primary_queue_endpoint
    AzureWebJobsStorage__tableServiceUri           = azurerm_storage_account.sa.primary_table_endpoint
    AzureWebJobsStorage__managedIdentityResourceId = azurerm_user_assigned_identity.uami.id

    FUNCTIONS_INPROC_NET8_ENABLED = 1
    LOGIC_APPS_POWERSHELL_VERSION = 7.4

    WEBSITE_SKIP_CONTENTSHARE_VALIDATION = "1"

    WEBSITE_VNET_ROUTE_ALL = 1

  }

  lifecycle {
    ignore_changes = [ storage_account_name,storage_account_access_key ]
  }


  tags = local.tags

  depends_on = [azurerm_role_assignment.ra-monitoring-metrics-publisher,
    azurerm_role_assignment.ra-storage-table-data-contributor,
    azurerm_role_assignment.ra-storage-queue-data-contributor,
    azurerm_role_assignment.ra-storage-account-contributor,
    azurerm_role_assignment.ra-storage-blob-data-owner,
    azurerm_private_endpoint.blobpe,
    azurerm_private_endpoint.queuepe,
    azurerm_private_endpoint.tablepe,
    azurerm_private_endpoint.filepe,
  ]


}

# Cleanup step to remove content share settings after deployment
# Currently, the AzureRM provider forces configuring a storage account
resource "terraform_data" "set-subscription" {
  provisioner "local-exec" {
    command = "az account set --subscription ${data.azurerm_client_config.current.subscription_id}"
  }

  depends_on = [ azurerm_logic_app_standard.logicapp ]
}

resource "terraform_data" "remove-unneeded-settings" {
  
  provisioner "local-exec" {
    command = <<EOT
      az functionapp config appsettings delete --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_logic_app_standard.logicapp.name} --setting-names WEBSITE_CONTENTAZUREFILECONNECTIONSTRING WEBSITE_CONTENTSHARE AzureWebJobsStorage
    EOT
  }

  depends_on = [ terraform_data.set-subscription ]
}

resource "terraform_data" "remove-AzureWebJobsStorage" {
  
  provisioner "local-exec" {
    command = "az functionapp config appsettings delete --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_logic_app_standard.logicapp.name} --setting-names AzureWebJobsStorage"    
  }

  depends_on = [ terraform_data.remove-unneeded-settings ]
}