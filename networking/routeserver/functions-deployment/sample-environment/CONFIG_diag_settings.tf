module "diag-fw" {

  count = local.include_firewall ? 1 : 0

  source = "../modules/diagnostics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  target_resource_id = module.azure_firewall[0].firewall_id

}

module "diag-gateway" {

  count = local.include_vnetgw ? 1 : 0

  source = "../modules/diagnostics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  target_resource_id = module.vpngateway[0].gateway_id

}

module "diag-storage" {

  source = "../modules/diagnostics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  target_resource_id = azurerm_storage_account.sa.id

}

# output "diag_groups" {
#   value = module.diag-fw.list_of_cat_groups
# }

# output "diag_types" {
#   value = module.diag-fw.list_of_cat_types
# }

# output "diag_metrics" {
#   value = module.diag-fw.list_of_metrics
# }
