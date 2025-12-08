module "ase-diag" {
  source                      = "./modules/diagnostics"
    target_resource_id = azurerm_app_service_environment_v3.ase.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id 
}

module "asp-diag" {
  source                      = "./modules/diagnostics"
    target_resource_id = azurerm_service_plan.plan.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id 
}

module "storage-diag" {
  source                      = "./modules/diagnostics"
    target_resource_id = azurerm_storage_account.sa.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id 
}
module "la-diag" {
  source                      = "./modules/diagnostics"
    target_resource_id = azurerm_log_analytics_workspace.law.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id 
}
module "logicapp-diag" {
  source                      = "./modules/diagnostics"
    target_resource_id = azurerm_logic_app_standard.logicapp.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id 
}

module "nsg-diag-app-service-environment" {
  source                      = "./modules/diagnostics"
    target_resource_id = azurerm_network_security_group.app-service-environment.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id 
}

module "nsg-diag-endpoints" {
  source                      = "./modules/diagnostics"
    target_resource_id = azurerm_network_security_group.nsg-endpoints.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id 
}

module "vnet-diag" {
  source                      = "./modules/diagnostics"
    target_resource_id = azurerm_virtual_network.vnet.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id 
}